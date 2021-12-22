import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frosty/models/stream.dart';
import 'package:frosty/screens/channel/video_chat.dart';
import 'package:frosty/widgets/profile_picture.dart';
import 'package:intl/intl.dart';

/// A tappable card widget that displays a stream's thumbnail and details.
class StreamCard extends StatelessWidget {
  final StreamTwitch streamInfo;

  const StreamCard({Key? key, required this.streamInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return VideoChat(
                title: streamInfo.title,
                userName: streamInfo.userName,
                userLogin: streamInfo.userLogin,
              );
            },
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Row(
          children: [
            Flexible(
              flex: 1,
              child: Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: [
                  CachedNetworkImage(
                    imageUrl: streamInfo.thumbnailUrl.replaceFirst('-{width}x{height}', '-440x248') + (DateTime.now().minute ~/ 5).toString(),
                    useOldImageOnUrlChange: true,
                  ),
                  Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      DateTime.now().difference(DateTime.parse(streamInfo.startedAt)).toString().split('.')[0],
                      style: const TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)),
                    ),
                  )
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProfilePicture(
                          userLogin: streamInfo.userLogin,
                          radius: 10.0,
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          streamInfo.userName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(streamInfo.title.replaceAll('\n', '')),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      streamInfo.gameName,
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      '${NumberFormat().format(streamInfo.viewerCount)} viewers',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}