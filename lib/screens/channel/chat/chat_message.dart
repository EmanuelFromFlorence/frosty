import 'package:flutter/material.dart';
import 'package:frosty/models/irc_message.dart';
import 'package:frosty/screens/channel/chat/chat_assets_store.dart';

class ChatMessage extends StatelessWidget {
  final IRCMessage ircMessage;
  final ChatAssetsStore assetsStore;
  final bool hideMessageIfBanned;
  final bool zeroWidth;
  final Timestamp timestamp;

  const ChatMessage({
    Key? key,
    required this.ircMessage,
    required this.assetsStore,
    this.hideMessageIfBanned = true,
    this.zeroWidth = false,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0);

    switch (ircMessage.command) {
      case Command.privateMessage:
      case Command.userState:
        // Render normal chat message (PRIVMSG).
        return Padding(
          padding: padding,
          child: Text.rich(
            TextSpan(
              children: ircMessage.generateSpan(
                style: DefaultTextStyle.of(context).style,
                emoteToObject: assetsStore.emoteToObject,
                twitchBadges: assetsStore.twitchBadgesToObject,
                ffzBadges: assetsStore.userToFFZBadges,
                zeroWidthEnabled: zeroWidth,
                timestamp: timestamp,
              ),
            ),
          ),
        );
      case Command.clearChat:
      case Command.clearMessage:
        // Render timeouts and bans
        final banDuration = ircMessage.tags['ban-duration'];
        return Padding(
          padding: padding,
          child: Opacity(
            opacity: 0.50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: ircMessage.generateSpan(
                      style: DefaultTextStyle.of(context).style,
                      emoteToObject: assetsStore.emoteToObject,
                      twitchBadges: assetsStore.twitchBadgesToObject,
                      ffzBadges: assetsStore.userToFFZBadges,
                      hideMessage: hideMessageIfBanned,
                      zeroWidthEnabled: zeroWidth,
                      timestamp: timestamp,
                    ),
                  ),
                ),
                const SizedBox(height: 5.0),
                if (banDuration == null)
                  if (ircMessage.command == Command.clearMessage)
                    const Text('Message Deleted', style: TextStyle(fontWeight: FontWeight.bold))
                  else
                    const Text('User Permanently Banned', style: TextStyle(fontWeight: FontWeight.bold))
                else
                  Text(
                    int.parse(banDuration) > 1 ? 'Timed out for $banDuration seconds' : 'Timed out for $banDuration second',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
              ],
            ),
          ),
        );
      case Command.notice:
        return Padding(
          padding: padding,
          child: Text.rich(
            TextSpan(
              text: ircMessage.message,
            ),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyText2?.color?.withOpacity(0.5),
            ),
          ),
        );
      case Command.userNotice:
        return Container(
          padding: padding,
          color: const Color(0xFF673AB7).withOpacity(0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ircMessage.tags['system-msg']!),
              const SizedBox(height: 5.0),
              if (ircMessage.message != null)
                Text.rich(
                  TextSpan(
                    children: ircMessage.generateSpan(
                      style: DefaultTextStyle.of(context).style,
                      emoteToObject: assetsStore.emoteToObject,
                      twitchBadges: assetsStore.twitchBadgesToObject,
                      ffzBadges: assetsStore.userToFFZBadges,
                      zeroWidthEnabled: zeroWidth,
                      timestamp: timestamp,
                    ),
                  ),
                ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
