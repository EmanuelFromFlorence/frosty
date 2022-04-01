import 'package:flutter/material.dart';
import 'package:frosty/models/emotes.dart';
import 'package:frosty/screens/channel/chat/emote_menu/emote_menu_section.dart';
import 'package:frosty/screens/channel/stores/chat_store.dart';
import 'package:frosty/widgets/section_header.dart';

class EmoteMenuPanel extends StatelessWidget {
  final ChatStore chatStore;
  final List<Emote> emotes;

  const EmoteMenuPanel({
    Key? key,
    required this.chatStore,
    required this.emotes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final globalEmotes = emotes
        .where((emote) =>
            emote.type == EmoteType.twitchGlobal ||
            emote.type == EmoteType.bttvGlobal ||
            emote.type == EmoteType.ffzGlobal ||
            emote.type == EmoteType.sevenTVGlobal)
        .toList();

    final channelEmotes = emotes
        .where((emote) =>
            emote.type == EmoteType.twitchChannel ||
            emote.type == EmoteType.bttvChannel ||
            emote.type == EmoteType.bttvShared ||
            emote.type == EmoteType.ffzChannel ||
            emote.type == EmoteType.sevenTVChannel)
        .toList();

    final subEmotes = emotes.where((emote) => emote.type == EmoteType.twitchSub).toList();
    final miscEmotes = emotes.where((emote) => emote.type == EmoteType.twitchUnlocked).toList();

    return CustomScrollView(
      slivers: [
        if (globalEmotes.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionHeader(
              'Global Emotes',
              padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            ),
          ),
          EmoteMenuSection(
            chatStore: chatStore,
            emotes: globalEmotes,
          ),
        ],
        if (channelEmotes.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionHeader('Channel Emotes'),
          ),
          EmoteMenuSection(
            chatStore: chatStore,
            emotes: channelEmotes,
          ),
        ],
        if (subEmotes.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionHeader('Subscribed Emotes'),
          ),
          EmoteMenuSection(
            chatStore: chatStore,
            emotes: subEmotes,
          ),
        ],
        if (miscEmotes.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionHeader('Unlocked Emotes'),
          ),
          EmoteMenuSection(
            chatStore: chatStore,
            emotes: miscEmotes,
          ),
        ],
      ],
    );
  }
}
