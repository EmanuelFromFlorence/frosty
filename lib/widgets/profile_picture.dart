import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frosty/api/twitch_api.dart';
import 'package:frosty/core/auth/auth_store.dart';
import 'package:frosty/models/user.dart';
import 'package:provider/provider.dart';

class ProfilePicture extends StatelessWidget {
  final String userLogin;
  final double? radius;

  const ProfilePicture({
    Key? key,
    required this.userLogin,
    this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Twitch.getUser(userLogin: userLogin, headers: context.read<AuthStore>().headersTwitch),
      builder: (context, AsyncSnapshot<UserTwitch?> snapshot) {
        return CircleAvatar(
          radius: radius,
          foregroundImage: snapshot.hasData && snapshot.data != null ? CachedNetworkImageProvider(snapshot.data!.profileImageUrl) : null,
        );
      },
    );
  }
}