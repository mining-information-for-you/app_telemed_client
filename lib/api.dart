import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:telemed_neurondata/api_config.dart';

class Api {
  final String _baseUrl = ApiConfig.apiUrl;

  Future<JoinResponse?> join(String tokenCall) async {
    final responseParticipant = await getParticipantByTokenCall(tokenCall);
    if (responseParticipant == null) {
      return JoinResponse(
        response: false,
        error: 'Erro ao obter dados do usuário, solicite um novo código',
      );
    }

    String url = "$_baseUrl/chime";

    try {
      final http.Response response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'externalUserId': responseParticipant.externalId.toString(),
          'requestId': responseParticipant.hashRoom,
          'nameAttendee': responseParticipant.name
        }),
        headers: {
          "Content-type": "application/json",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> joinInfoMap = jsonDecode(response.body);
        JoinInfo joinInfo = JoinInfo.fromJson(joinInfoMap);
        return JoinResponse(response: true, content: joinInfo);
      }
    } catch (e) {
      return JoinResponse(response: false, error: e.toString());
    }
    return null;
  }

  Map<String, dynamic> joinInfoToJSON(JoinInfo info) {
    Map<String, dynamic> flattenedJSON = {
      "MeetingId": info.meeting.meetingId,
      "ExternalMeetingId": info.meeting.externalMeetingId,
      "MediaRegion": info.meeting.mediaRegion,
      "AudioHostUrl": info.meeting.mediaPlacement.audioHostUrl,
      "AudioFallbackUrl": info.meeting.mediaPlacement.audioFallbackUrl,
      "SignalingUrl": info.meeting.mediaPlacement.signalingUrl,
      "TurnControlUrl": info.meeting.mediaPlacement.turnControllerUrl,
      "ExternalUserId": info.attendee.externalUserId,
      "AttendeeId": info.attendee.attendeeId,
      "JoinToken": info.attendee.joinToken
    };

    return flattenedJSON;
  }

  Future<ParticipantResponse?> getParticipantByTokenCall(
    String tokenCall,
  ) async {
    String url = "$_baseUrl/panel/participant/$tokenCall";

    try {
      final http.Response response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-type": "application/json",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> participantMap = jsonDecode(response.body);
        ParticipantInfo participantInfo =
            ParticipantInfo.fromJson(participantMap);

        final roomAvailable = await getRoomAvailable(participantInfo.hashRoom);

        if (roomAvailable == null || roomAvailable.active == false) return null;

        final participantAvailable = await getParticipantAvailable(
          participantInfo.hashRoom,
          participantInfo.userId,
          participantInfo.clientId,
          participantInfo.customerServiceId,
          participantInfo.name,
        );

        if (participantAvailable == null ||
            participantAvailable.available == false) return null;

        return ParticipantResponse(
          participantInfo.externalId,
          participantInfo.name,
          participantInfo.hashRoom,
          participantInfo.message,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<RoomAvailableResponse?> getRoomAvailable(
    String hashRoom,
  ) async {
    String url = "$_baseUrl/panel/room/available";

    try {
      final http.Response response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'hash': hashRoom,
        }),
        headers: {
          "Content-type": "application/json",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> roomAvailableMap = jsonDecode(response.body);
        RoomAvailableInfo roomAvailableInfo =
            RoomAvailableInfo.fromJson(roomAvailableMap);

        return RoomAvailableResponse(roomAvailableInfo.active);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<ParticipantAvailableResponse?> getParticipantAvailable(
    String hashRoom,
    int userId,
    int clientId,
    int customerServiceId,
    String name,
  ) async {
    String url = "$_baseUrl/panel/participant/available";

    try {
      final http.Response response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'hash': hashRoom,
          'customer_service_id': customerServiceId,
          'user_id': userId,
          'client_id': clientId,
          'name': name,
        }),
        headers: {
          "Content-type": "application/json",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> participantAvailableMap =
            jsonDecode(response.body);
        ParticipantAvailableInfo participantAvailableInfo =
            ParticipantAvailableInfo.fromJson(participantAvailableMap);

        return ParticipantAvailableResponse(participantAvailableInfo.available);
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

class JoinInfo {
  final Meeting meeting;

  final AttendeeInfo attendee;

  JoinInfo(this.meeting, this.attendee);

  factory JoinInfo.fromJson(Map<String, dynamic> json) {
    return JoinInfo(Meeting.fromJson(json), AttendeeInfo.fromJson(json));
  }
}

class Meeting {
  final String meetingId;
  final String? externalMeetingId;
  final String mediaRegion;
  final MediaPlacement mediaPlacement;

  Meeting(this.meetingId, this.externalMeetingId, this.mediaRegion,
      this.mediaPlacement);

  factory Meeting.fromJson(Map<String, dynamic> json) {
    var meetingMap = json['meeting']['Meeting'];
    dynamic externalMeetingId;

    externalMeetingId = meetingMap['ExternalMeetingId'] ?? '';

    return Meeting(
      meetingMap['MeetingId'],
      externalMeetingId,
      meetingMap['MediaRegion'],
      MediaPlacement.fromJson(json),
    );
  }
}

class MediaPlacement {
  final String audioHostUrl;
  final String audioFallbackUrl;
  final String signalingUrl;
  final String turnControllerUrl;

  MediaPlacement(this.audioHostUrl, this.audioFallbackUrl, this.signalingUrl,
      this.turnControllerUrl);

  factory MediaPlacement.fromJson(Map<String, dynamic> json) {
    var mediaPlacementMap = json['meeting']['Meeting']['MediaPlacement'];
    return MediaPlacement(
        mediaPlacementMap['AudioHostUrl'],
        mediaPlacementMap['AudioFallbackUrl'],
        mediaPlacementMap['SignalingUrl'],
        mediaPlacementMap['TurnControlUrl']);
  }
}

class AttendeeInfo {
  final String externalUserId;
  final String attendeeId;
  final String joinToken;

  AttendeeInfo(this.externalUserId, this.attendeeId, this.joinToken);

  factory AttendeeInfo.fromJson(Map<String, dynamic> json) {
    var attendeeMap = json['attendee']['Attendee'];

    return AttendeeInfo(attendeeMap['ExternalUserId'],
        attendeeMap['AttendeeId'], attendeeMap['JoinToken']);
  }
}

class JoinResponse {
  final bool response;
  final JoinInfo? content;
  final String? error;

  JoinResponse({required this.response, this.content, this.error});
}

class ParticipantInfo {
  final int externalId;
  final int clientId;
  final int userId;
  final int customerServiceId;
  final String name;
  final String hashRoom;
  final String? message;

  ParticipantInfo(
    this.externalId,
    this.clientId,
    this.userId,
    this.customerServiceId,
    this.name,
    this.hashRoom,
    this.message,
  );

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      json['user_id'] ?? json['client_id'],
      json['client_id'],
      json['user_id'],
      json['customer_service_id'],
      json['name'],
      json['hash_room'],
      json['message'],
    );
  }
}

class ParticipantResponse {
  final int externalId;
  final String name;
  final String hashRoom;
  final String? message;

  ParticipantResponse(this.externalId, this.name, this.hashRoom, this.message);
}

class RoomAvailableInfo {
  final bool active;

  RoomAvailableInfo(this.active);

  factory RoomAvailableInfo.fromJson(Map<String, dynamic> json) {
    return RoomAvailableInfo(json['active']);
  }
}

class RoomAvailableResponse {
  final bool active;

  RoomAvailableResponse(this.active);
}

class ParticipantAvailableInfo {
  final bool available;

  ParticipantAvailableInfo(this.available);

  factory ParticipantAvailableInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantAvailableInfo(json['available']);
  }
}

class ParticipantAvailableResponse {
  final bool available;

  ParticipantAvailableResponse(this.available);
}
