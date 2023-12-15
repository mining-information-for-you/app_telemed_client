import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telemed_neurondata/attendee.dart';
import 'package:telemed_neurondata/interface/audio_video_interface.dart';
import 'package:telemed_neurondata/interface/realtime_interface.dart';
import 'package:telemed_neurondata/interface/video_tile_interface.dart';
import 'package:telemed_neurondata/response_enums.dart';
import 'package:telemed_neurondata/view_models/meeting_view_model.dart';

import 'logger.dart';
import 'video_tile.dart';

class MethodChannelCoordinator extends ChangeNotifier {
  final MethodChannel methodChannel =
      const MethodChannel("com.neurondata.telemed_ha.methodChannel");

  RealtimeInterface? realtimeObserver;
  VideoTileInterface? videoTileObserver;
  AudioVideoInterface? audioVideoObserver;

  void initializeMethodCallHandler() {
    methodChannel.setMethodCallHandler(methodCallHandler);
    logger.i("Flutter Method Call Handler initialized.");
  }

  void initializeRealtimeObserver(RealtimeInterface realtimeInterface) {
    realtimeObserver = realtimeInterface;
  }

  void initializeAudioVideoObserver(AudioVideoInterface audioVideoInterface) {
    audioVideoObserver = audioVideoInterface;
  }

  void initializeVideoTileObserver(VideoTileInterface videoTileInterface) {
    videoTileObserver = videoTileInterface;
  }

  void initializeObservers(MeetingViewModel meetingProvider) {
    initializeRealtimeObserver(meetingProvider);
    initializeAudioVideoObserver(meetingProvider);
    initializeVideoTileObserver(meetingProvider);
    logger.d("Observers initialized");
  }

  Future<MethodChannelResponse?> callMethod(String methodName,
      [dynamic args]) async {
    logger.d("Calling $methodName through method channel with args: $args");
    try {
      dynamic response = await methodChannel.invokeMethod(methodName, args);
      return MethodChannelResponse.fromJson(response);
    } catch (e) {
      logger.e(e.toString());
      return MethodChannelResponse(false, null);
    }
  }

  Future<void> methodCallHandler(MethodCall call) async {
    logger.d(
        "Recieved method call ${call.method} with arguments: ${call.arguments}");

    switch (call.method) {
      case MethodCallOption.join:
        final Attendee attendee = Attendee.fromJson(call.arguments);
        realtimeObserver?.attendeeDidJoin(attendee);
        break;
      case MethodCallOption.leave:
        final Attendee attendee = Attendee.fromJson(call.arguments);
        realtimeObserver?.attendeeDidLeave(attendee, didDrop: false);
        break;
      case MethodCallOption.drop:
        final Attendee attendee = Attendee.fromJson(call.arguments);
        realtimeObserver?.attendeeDidLeave(attendee, didDrop: true);
        break;
      case MethodCallOption.mute:
        final Attendee attendee = Attendee.fromJson(call.arguments);
        realtimeObserver?.attendeeDidMute(attendee);
        break;
      case MethodCallOption.unmute:
        final Attendee attendee = Attendee.fromJson(call.arguments);
        realtimeObserver?.attendeeDidUnmute(attendee);
        break;
      case MethodCallOption.videoTileAdd:
        final String attendeeId = call.arguments["attendeeId"];
        final VideoTile videoTile = VideoTile.fromJson(call.arguments);
        videoTileObserver?.videoTileDidAdd(attendeeId, videoTile);
        break;
      case MethodCallOption.videoTileRemove:
        final String attendeeId = call.arguments["attendeeId"];
        final VideoTile videoTile = VideoTile.fromJson(call.arguments);
        videoTileObserver?.videoTileDidRemove(attendeeId, videoTile);
        break;
      case MethodCallOption.audioSessionDidStop:
        audioVideoObserver?.audioSessionDidStop();
        break;
      default:
        logger.w(
            "Method ${call.method} with args ${call.arguments} does not exist");
    }
  }
}

class MethodChannelResponse {
  late bool result;
  dynamic arguments;

  MethodChannelResponse(this.result, this.arguments);

  factory MethodChannelResponse.fromJson(dynamic json) {
    return MethodChannelResponse(json["result"], json["arguments"]);
  }
}
