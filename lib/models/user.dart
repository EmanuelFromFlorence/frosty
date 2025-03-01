import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

// Twitch (default) user
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class UserTwitch {
  final String id;
  final String login;
  final String displayName;
  final String type;
  final String broadcasterType;
  final String description;
  final String profileImageUrl;
  final String offlineImageUrl;
  final int viewCount;
  final String createdAt;

  const UserTwitch(
    this.id,
    this.login,
    this.displayName,
    this.type,
    this.broadcasterType,
    this.description,
    this.profileImageUrl,
    this.offlineImageUrl,
    this.viewCount,
    this.createdAt,
  );

  factory UserTwitch.fromJson(Map<String, dynamic> json) => _$UserTwitchFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class UserBlockedTwitch {
  final String userId;
  final String userLogin;
  final String displayName;

  const UserBlockedTwitch(
    this.userId,
    this.userLogin,
    this.displayName,
  );

  factory UserBlockedTwitch.fromJson(Map<String, dynamic> json) => _$UserBlockedTwitchFromJson(json);
}
