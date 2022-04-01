import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frosty/constants/constants.dart';
import 'package:frosty/models/badges.dart';
import 'package:frosty/models/category.dart';
import 'package:frosty/models/channel.dart';
import 'package:frosty/models/chatters.dart';
import 'package:frosty/models/emotes.dart';
import 'package:frosty/models/stream.dart';
import 'package:frosty/models/user.dart';
import 'package:http/http.dart';

/// The Twitch service for making API calls.
class TwitchApi {
  final Client _client;

  const TwitchApi(this._client);

  /// Returns a list of a channel's Twitch emotes given their [id].
  Future<List<Emote>> getEmotesChannel({
    required String id,
    required Map<String, String> headers,
  }) async {
    final url = Uri.parse('https://api.twitch.tv/helix/chat/emotes?broadcaster_id=$id');

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body)['data'] as List;
      final emotes = decoded.map((emote) => EmoteTwitch.fromJson(emote)).toList();

      return emotes.map((emote) {
        switch (emote.emoteType) {
          case 'bitstier':
            return Emote.fromTwitch(emote, EmoteType.twitchBits);
          case 'follower':
            return Emote.fromTwitch(emote, EmoteType.twitchFollower);
          case 'subscriptions':
            return Emote.fromTwitch(emote, EmoteType.twitchChannel);
          default:
            return Emote.fromTwitch(emote, EmoteType.twitchChannel);
        }
      }).toList();
    } else {
      return Future.error('Failed to get Twitch channel emotes.');
    }
  }

  /// Returns a list of Twitch emotes under the provided [setId].
  Future<List<Emote>> getEmotesSets({
    required String setId,
    required Map<String, String> headers,
  }) async {
    final url = Uri.parse('https://api.twitch.tv/helix/chat/emotes/set?emote_set_id=$setId');

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body)['data'] as List;
      final emotes = decoded.map((emote) => EmoteTwitch.fromJson(emote)).toList();

      return emotes.map((emote) {
        switch (emote.emoteType) {
          case 'globals':
          case 'smilies':
            return Emote.fromTwitch(emote, EmoteType.twitchGlobal);
          case 'subscriptions':
            return Emote.fromTwitch(emote, EmoteType.twitchSub);
          default:
            return Emote.fromTwitch(emote, EmoteType.twitchUnlocked);
        }
      }).toList();
    } else {
      return Future.error('Failed to get Twitch emotes set.');
    }
  }

  /// Returns a map of global Twitch badges to their [Emote] object.
  Future<Map<String, Badge>> getBadgesGlobal() async {
    final url = Uri.parse('https://badges.twitch.tv/v1/badges/global/display');

    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final result = <String, Badge>{};
      final decoded = jsonDecode(response.body)['badge_sets'] as Map;
      decoded.forEach((id, versions) => (versions['versions'] as Map)
          .forEach((version, badgeInfo) => result['$id/$version'] = Badge.fromTwitch(BadgeInfoTwitch.fromJson(badgeInfo))));

      return result;
    } else {
      return Future.error('Failed to get Twitch global badges.');
    }
  }

  /// Returns a map of a channel's Twitch badges to their [Emote] object.
  Future<Map<String, Badge>> getBadgesChannel({required String id}) async {
    final url = Uri.parse('https://badges.twitch.tv/v1/badges/channels/$id/display');

    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final result = <String, Badge>{};
      final decoded = jsonDecode(response.body)['badge_sets'] as Map;
      decoded.forEach((id, versions) => (versions['versions'] as Map)
          .forEach((version, badgeInfo) => result['$id/$version'] = Badge.fromTwitch(BadgeInfoTwitch.fromJson(badgeInfo))));

      return result;
    } else {
      return Future.error('Failed to get Twitch channel badges.');
    }
  }

  /// Returns the user's info given their token through [headers].
  Future<UserTwitch> getUserInfo({required Map<String, String> headers}) async {
    final url = Uri.parse('https://api.twitch.tv/helix/users');

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body)['data'] as List;

      return UserTwitch.fromJson(userData.first);
    } else {
      return Future.error('Failed to get Twitch user info');
    }
  }

  /// Returns a token for an anonymous user.
  Future<String> getDefaultToken() async {
    final url = Uri(
      scheme: 'https',
      host: 'id.twitch.tv',
      path: '/oauth2/token',
      queryParameters: {
        'client_id': clientId,
        'client_secret': secret,
        'grant_type': 'client_credentials',
      },
    );

    final response = await _client.post(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['access_token'];
    } else {
      return Future.error('Failed to get default token.');
    }
  }

  /// Returns a bool indicating the validity of the given token.
  Future<bool> validateToken({required String token}) async {
    final url = Uri.parse('https://id.twitch.tv/oauth2/validate');

    final response = await _client.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      debugPrint('Token validated!');
      return true;
    } else {
      debugPrint('Token invalidated :(');
      return false;
    }
  }

  /// Returns a [StreamsTwitch] object that contains the top 20 streams and a cursor for further requests.
  Future<StreamsTwitch> getTopStreams({
    required Map<String, String> headers,
    String? cursor,
  }) async {
    final url = Uri.parse(cursor == null ? 'https://api.twitch.tv/helix/streams' : 'https://api.twitch.tv/helix/streams?after=$cursor');

    final response = await _client.get(url, headers: headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return StreamsTwitch.fromJson(decoded);
    } else {
      return Future.error('Failed to get top streams: ${decoded['message']}');
    }
  }

  /// Returns a [StreamsTwitch] object that contains the given user ID's top 20 followed streams and a cursor for further requests.
  Future<StreamsTwitch> getFollowedStreams({
    required String id,
    required Map<String, String> headers,
    String? cursor,
  }) async {
    final url = Uri.parse(cursor == null
        ? 'https://api.twitch.tv/helix/streams/followed?user_id=$id'
        : 'https://api.twitch.tv/helix/streams/followed?user_id=$id&after=$cursor');

    final response = await _client.get(url, headers: headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return StreamsTwitch.fromJson(decoded);
    } else {
      return Future.error('Failed to get followed streams: ${decoded['message']}');
    }
  }

  /// Returns a [StreamsTwitch] object that contains the list of streams under the given game/category ID.
  Future<StreamsTwitch> getStreamsUnderCategory({
    required String gameId,
    required Map<String, String> headers,
    String? cursor,
  }) async {
    final url = Uri.parse(
        cursor == null ? 'https://api.twitch.tv/helix/streams?game_id=$gameId' : 'https://api.twitch.tv/helix/streams?game_id=$gameId&after=$cursor');

    final response = await _client.get(url, headers: headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return StreamsTwitch.fromJson(decoded);
    } else {
      return Future.error('Failed to get streams under category: ${decoded['message']}');
    }
  }

  /// Returns a [StreamTwitch] object containing the stream info associated with the given [userLogin].
  Future<StreamTwitch> getStream({
    required String userLogin,
    required Map<String, String> headers,
  }) async {
    final uri = Uri.parse('https://api.twitch.tv/helix/streams?user_login=$userLogin');

    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['data'] as List;

      if (data.isNotEmpty) {
        return StreamTwitch.fromJson(data.first);
      } else {
        return Future.error('$userLogin is offline');
      }
    } else {
      return Future.error('Failed to get stream info.');
    }
  }

  /// Returns a [UserTwitch] object containing the user info associated with the given [userLogin].
  Future<UserTwitch> getUser({
    String? userLogin,
    String? id,
    required Map<String, String> headers,
  }) async {
    final url = Uri.parse(id != null ? 'https://api.twitch.tv/helix/users?id=$id' : 'https://api.twitch.tv/helix/users?login=$userLogin');

    final response = await _client.get(url, headers: headers);
    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final userData = decoded['data'] as List;

      if (userData.isNotEmpty) {
        return UserTwitch.fromJson(userData.first);
      } else {
        return Future.error('User does not exist!');
      }
    } else {
      return Future.error('Failed to get user: ${decoded['message']}');
    }
  }

  /// Returns a [Channel] object containing a channels's info associated with the given [userId].
  Future<Channel> getChannel({
    required String userId,
    required Map<String, String> headers,
  }) async {
    final url = Uri.parse('https://api.twitch.tv/helix/channels?broadcaster_id=$userId');

    final response = await _client.get(url, headers: headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final channelData = decoded['data'] as List;

      if (channelData.isNotEmpty) {
        return Channel.fromJson(channelData.first);
      } else {
        return Future.error('Channel does not exist');
      }
    } else {
      return Future.error('Failed to get channel: ${decoded['message']}');
    }
  }

  /// Returns a list of [ChannelQuery] objects closest matching the given [query].
  Future<List<ChannelQuery>> searchChannels({
    required String query,
    required Map<String, String> headers,
  }) async {
    final url = Uri.parse('https://api.twitch.tv/helix/search/channels?first=8&query=$query');

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final channelData = jsonDecode(response.body)['data'] as List;

      return channelData.map((e) => ChannelQuery.fromJson(e)).toList();
    } else {
      return Future.error('Failed to get channels.');
    }
  }

  /// Returns a [CategoriesTwitch] object containing the next top 20 categories/games and a cursor for further requests.
  Future<CategoriesTwitch> getTopCategories({
    required Map<String, String> headers,
    String? cursor,
  }) async {
    final url = Uri.parse(cursor == null ? 'https://api.twitch.tv/helix/games/top' : 'https://api.twitch.tv/helix/games/top?after=$cursor');

    final response = await _client.get(url, headers: headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return CategoriesTwitch.fromJson(decoded);
    } else {
      return Future.error('Failed to get top categories: ${decoded['message']}');
    }
  }

  /// Returns a [CategoriesTwitch] object containing the category info corresponding to the provided [gameId].
  Future<CategoriesTwitch> getCategory({
    required Map<String, String> headers,
    required String gameId,
  }) async {
    final url = Uri.parse('https://api.twitch.tv/helix/games?id=$gameId');

    final response = await _client.get(url, headers: headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return CategoriesTwitch.fromJson(decoded);
    } else {
      return Future.error('Failed to get category: ${decoded['message']}');
    }
  }

  /// Returns a [CategoriesTwitch] containing up to 20 categories/games closest matching the [query] and a cursor for further requests.
  Future<CategoriesTwitch> searchCategories({
    required Map<String, String> headers,
    required String query,
    String? cursor,
  }) async {
    final url = Uri.parse(cursor == null
        ? 'https://api.twitch.tv/helix/search/categories?first=8&query=$query'
        : 'https://api.twitch.tv/helix/search/categories?first=8&query=$query&after=$cursor');

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return CategoriesTwitch.fromJson(decoded);
    } else {
      return Future.error('Failed to get categories.');
    }
  }

  /// Returns the sub count associated with the given [userId].
  Future<int> getSubscriberCount({
    required String userId,
    required Map<String, String> headers,
  }) async {
    final uri = Uri.parse('https://api.twitch.tv/helix/subscriptions?broadcaster_id=$userId');

    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return decoded['total'] as int;
    } else {
      return Future.error('Failed to get sub count.');
    }
  }

  /// Returns a [ChatUsers] object containing the names of chatters in the given [userLogin]'s chat.
  Future<ChatUsers> getChatters({required String userLogin}) async {
    final uri = Uri.parse('https://tmi.twitch.tv/group/user/$userLogin/chatters');

    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return ChatUsers.fromJson(decoded);
    } else {
      return Future.error('Failed to get chatters.');
    }
  }

  /// Returns a user's list of blocked users given their id.
  Future<List<UserBlockedTwitch>> getUserBlockedList({
    required String id,
    required Map<String, String> headers,
    String? cursor,
  }) async {
    final url = Uri.parse(cursor == null
        ? 'https://api.twitch.tv/helix/users/blocks?first=100&broadcaster_id=$id'
        : 'https://api.twitch.tv/helix/users/blocks?first=100&broadcaster_id=$id&after=$cursor');

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final cursor = decoded['pagination']['cursor'];
      final blockedList = decoded['data'] as List;

      if (blockedList.isNotEmpty) {
        final result = blockedList.map((e) => UserBlockedTwitch.fromJson(e)).toList();

        if (cursor != null) {
          result.addAll(await getUserBlockedList(id: id, cursor: cursor, headers: headers));
        }

        return result;
      } else {
        debugPrint('User does not have anyone blocked');
        return [];
      }
    } else {
      return Future.error('User does not exist!');
    }
  }

  // Blocks the user with the given ID and returns true on success or false on failure.
  Future<bool> blockUser({required String userId, required Map<String, String> headers}) async {
    final url = Uri.parse('https://api.twitch.tv/helix/users/blocks?target_user_id=$userId');

    final response = await _client.put(url, headers: headers);
    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  // Unblocks the user with the given ID and returns true on success or false on failure.
  Future<bool> unblockUser({required String userId, required Map<String, String> headers}) async {
    final url = Uri.parse('https://api.twitch.tv/helix/users/blocks?target_user_id=$userId');

    final response = await _client.delete(url, headers: headers);
    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }
}
