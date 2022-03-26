import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:frosty/api/twitch_api.dart';
import 'package:frosty/core/auth/auth_store.dart';
import 'package:frosty/screens/channel/chat/widgets/chat_user_modal.dart';
import 'package:frosty/screens/channel/stores/chat_details_store.dart';
import 'package:frosty/screens/channel/stores/chat_store.dart';
import 'package:frosty/widgets/loading_indicator.dart';
import 'package:frosty/widgets/scroll_to_top_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChattersList extends StatefulWidget {
  final ChatDetailsStore chatDetails;
  final ChatStore chatStore;
  final String userLogin;

  const ChattersList({
    Key? key,
    required this.chatDetails,
    required this.chatStore,
    required this.userLogin,
  }) : super(key: key);

  @override
  _ChattersListState createState() => _ChattersListState();
}

class _ChattersListState extends State<ChattersList> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge || _scrollController.position.outOfRange) {
        widget.chatDetails.showJumpButton = false;
      } else {
        widget.chatDetails.showJumpButton = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontWeight: FontWeight.bold);

    const headers = [
      'Broadcaster',
      'Staff',
      'Admins',
      'Global Moderators',
      'Moderators',
      'VIPs',
      'Viewers',
    ];

    final chatDetailStore = widget.chatDetails;
    chatDetailStore.updateChatters(widget.userLogin);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            controller: _textController,
            autocorrect: false,
            onChanged: (text) => chatDetailStore.filterText = text,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filter',
              contentPadding: const EdgeInsets.all(10.0),
              suffixIcon: IconButton(
                tooltip: 'Clear Filter',
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  chatDetailStore.filterText = '';
                  _textController.clear();
                },
                icon: const Icon(Icons.clear),
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await chatDetailStore.updateChatters(widget.userLogin);
            },
            child: Stack(
              alignment: AlignmentDirectional.bottomCenter,
              children: [
                Observer(
                  builder: (context) {
                    if (chatDetailStore.error != null) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Failed to get chatters'),
                          TextButton(
                            onPressed: () => chatDetailStore.updateChatters(widget.userLogin),
                            child: const Text('Try Again'),
                          )
                        ],
                      );
                    }

                    if (chatDetailStore.chatUsers == null) {
                      return const LoadingIndicator(subtitle: Text('Getting chatters...'));
                    }

                    return CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Chatters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                const SizedBox(height: 5.0),
                                Text('${NumberFormat().format(chatDetailStore.chatUsers?.chatterCount)} in chat'),
                              ],
                            ),
                          ),
                        ),
                        ...chatDetailStore.filteredUsers.expandIndexed(
                          (index, users) => [
                            if (users.isNotEmpty) ...[
                              SliverPadding(
                                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 20.0),
                                sliver: SliverToBoxAdapter(
                                  child: Text(
                                    headers[index],
                                    style: textStyle,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 5.0),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => InkWell(
                                      child: Text(users[index]),
                                      onLongPress: () async {
                                        final userInfo = await context
                                            .read<TwitchApi>()
                                            .getUser(headers: context.read<AuthStore>().headersTwitch, userLogin: users[index]);

                                        showModalBottomSheet(
                                          context: context,
                                          builder: (context) => ChatUserModal(
                                            chatStore: widget.chatStore,
                                            username: userInfo.login,
                                            userId: userInfo.id,
                                            displayName: userInfo.displayName,
                                          ),
                                        );
                                      },
                                    ),
                                    childCount: users.length,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        )
                      ],
                    );
                  },
                ),
                SafeArea(
                  child: Observer(
                    builder: (context) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: chatDetailStore.showJumpButton ? ScrollToTopButton(scrollController: _scrollController) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
