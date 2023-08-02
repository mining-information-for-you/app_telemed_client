import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mvp_chime_flutter/view_models/meeting_view_model.dart';
import 'package:mvp_chime_flutter/views/screenshare.dart';
import 'package:provider/provider.dart';

import '../logger.dart';

class MeetingView extends StatelessWidget {
  const MeetingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final meetingProvider = Provider.of<MeetingViewModel>(context);
    final orientation = MediaQuery.of(context).orientation;

    if (!meetingProvider.isMeetingActive) {
      Navigator.maybePop(context);
    }

    return Scaffold(
      body: meetingBodyPortrait(meetingProvider, orientation, context),
    );
  }

  //
  // —————————————————————————— Portrait Body ——————————————————————————————————————
  //

  Widget meetingBodyPortrait(MeetingViewModel meetingProvider,
      Orientation orientation, BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: displayVideoTiles(
              meetingProvider,
              orientation,
              context,
            ),
          ),
        ),
        WillPopScope(
          onWillPop: () async {
            meetingProvider.stopMeeting();
            return true;
          },
          child: const SizedBox(height: 0),
        ),
        displayAttendeeLocal(meetingProvider, context),
      ],
    );
  }

  Widget displayAttendeeLocal(
      MeetingViewModel meetingProvider, BuildContext context) {
    Widget attendeeLocal = const SizedBox(height: 0);
    if (meetingProvider.currAttendees
        .containsKey(meetingProvider.localAttendeeId)) {
      attendeeLocal = localListInfo(meetingProvider, context);
    }

    return attendeeLocal;
  }

  Widget localListInfo(MeetingViewModel meetingProvider, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.phone_disabled),
            iconSize: 32,
            color: Colors.red,
            onPressed: () {
              meetingProvider.stopMeeting();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: Icon(localMuteIcon(meetingProvider)),
            iconSize: 32,
            color: Colors.blue,
            onPressed: () {
              meetingProvider.sendLocalMuteToggle();
            },
          ),
          IconButton(
            icon: Icon(localVideoIcon(meetingProvider)),
            iconSize: 32,
            constraints: const BoxConstraints(),
            color: Colors.blue,
            onPressed: () {
              meetingProvider.sendLocalVideoTileOn();
            },
          ),
        ],
      ),
    );
  }

  //
  // —————————————————————————— Helpers ——————————————————————————————————————
  //

  void openFullscreenDialog(
      BuildContext context, int? params, MeetingViewModel meetingProvider) {
    Widget contentTile;

    if (Platform.isIOS) {
      contentTile = UiKitView(
        viewType: "videoTile",
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isAndroid) {
      contentTile = PlatformViewLink(
        viewType: 'videoTile',
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          final AndroidViewController controller =
              PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: 'videoTile',
            layoutDirection: TextDirection.ltr,
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged,
          );
          controller
              .addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
          controller.create();
          return controller;
        },
      );
    } else {
      contentTile = const Text("Unrecognized Platform.");
    }

    if (!meetingProvider.isReceivingScreenShare) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const MeetingView()));
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                        onDoubleTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MeetingView())),
                        child: contentTile),
                  ),
                ),
              ],
            ),
          );
        },
        fullscreenDialog: true,
      ),
    );
  }

  List<Widget> displayVideoTiles(MeetingViewModel meetingProvider,
      Orientation orientation, BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget screenShareWidget = Container(
      child: videoTile(
        meetingProvider,
        context,
        isLocal: false,
        isContent: true,
      ),
    );
    Widget localVideoTile = SizedBox(
      width: size.width,
      height: size.height,
      child: Expanded(
        child: FittedBox(
          fit: BoxFit.cover,
          child: videoTile(
            meetingProvider,
            context,
            isLocal: true,
            isContent: false,
          ),
        ),
      ),
    );
    Widget remoteVideoTile =
        videoTile(meetingProvider, context, isLocal: false, isContent: false);

    if (meetingProvider.currAttendees
        .containsKey(meetingProvider.contentAttendeeId)) {
      if (meetingProvider.isReceivingScreenShare) {
        return [screenShareWidget];
      }
    }

    List<Widget> videoTiles = [];

    if (meetingProvider
            .currAttendees[meetingProvider.localAttendeeId]?.isVideoOn ??
        false) {
      if (meetingProvider
              .currAttendees[meetingProvider.localAttendeeId]?.videoTile !=
          null) {
        videoTiles.add(localVideoTile);
      }
    }
    if (meetingProvider.currAttendees.length > 1) {
      if (meetingProvider.currAttendees
          .containsKey(meetingProvider.remoteAttendeeId)) {
        if ((meetingProvider.currAttendees[meetingProvider.remoteAttendeeId]
                    ?.isVideoOn ??
                false) &&
            meetingProvider.currAttendees[meetingProvider.remoteAttendeeId]
                    ?.videoTile !=
                null) {
          videoTiles.add(Expanded(child: remoteVideoTile));
        }
      }
    }

    if (videoTiles.isEmpty) {
      Widget emptyVideos = Column(
        children: [
          const Text(
            "Sem vídeo aberto",
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          Icon(
            Icons.videocam_off,
            size: 94,
            color: Colors.grey.withAlpha(500),
          )
        ],
      );
      if (orientation == Orientation.portrait) {
        videoTiles.add(
          emptyVideos,
        );
      } else {
        videoTiles.add(
          Center(
            widthFactor: 2.5,
            child: emptyVideos,
          ),
        );
      }
    }

    return videoTiles;
  }

  Widget contentVideoTile(
      int? paramsVT, MeetingViewModel meetingProvider, BuildContext context) {
    Widget videoTile;
    if (Platform.isIOS) {
      videoTile = UiKitView(
        viewType: "videoTile",
        creationParams: paramsVT,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isAndroid) {
      videoTile = PlatformViewLink(
        viewType: 'videoTile',
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          final AndroidViewController controller =
              PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: 'videoTile',
            layoutDirection: TextDirection.ltr,
            creationParams: paramsVT,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged,
          );
          controller
              .addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
          controller.create();
          return controller;
        },
      );
    } else {
      videoTile = const Text("Unrecognized Platform.");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 200,
        height: 230,
        child: GestureDetector(
          onDoubleTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ScreenShare(paramsVT: paramsVT)));
          },
          child: videoTile,
        ),
      ),
    );
  }

  Widget videoTile(MeetingViewModel meetingProvider, BuildContext context,
      {required bool isLocal, required bool isContent}) {
    int? paramsVT;

    if (isContent) {
      if (meetingProvider.contentAttendeeId != null) {
        if (meetingProvider
                .currAttendees[meetingProvider.contentAttendeeId]?.videoTile !=
            null) {
          paramsVT = meetingProvider
              .currAttendees[meetingProvider.contentAttendeeId]
              ?.videoTile
              ?.tileId as int;
          return contentVideoTile(paramsVT, meetingProvider, context);
        }
      }
    } else if (isLocal) {
      paramsVT = meetingProvider
          .currAttendees[meetingProvider.localAttendeeId]?.videoTile?.tileId;
    } else {
      paramsVT = meetingProvider
          .currAttendees[meetingProvider.remoteAttendeeId]?.videoTile?.tileId;
    }

    Widget videoTile;
    if (Platform.isIOS) {
      videoTile = UiKitView(
        viewType: "videoTile",
        creationParams: paramsVT,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isAndroid) {
      videoTile = PlatformViewLink(
        viewType: 'videoTile',
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          final AndroidViewController controller =
              PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: 'videoTile',
            layoutDirection: TextDirection.ltr,
            creationParams: paramsVT,
            creationParamsCodec: const StandardMessageCodec(),
          );
          controller
              .addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
          controller.create();
          return controller;
        },
      );
    } else {
      videoTile = const Text("Unrecognized Platform.");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 200,
        height: 230,
        child: videoTile,
      ),
    );
  }

  List<Widget> getSimpleDialogOptionsAudioDevices(
      MeetingViewModel meetingProvider, BuildContext context) {
    List<Widget> dialogOptions = [];
    FontWeight weight;
    for (var i = 0; i < meetingProvider.deviceList.length; i++) {
      if (meetingProvider.deviceList[i] ==
          meetingProvider.selectedAudioDevice) {
        weight = FontWeight.bold;
      } else {
        weight = FontWeight.normal;
      }
      dialogOptions.add(
        SimpleDialogOption(
          child: Text(
            meetingProvider.deviceList[i] as String,
            style: TextStyle(color: Colors.black, fontWeight: weight),
          ),
          onPressed: () {
            logger.i("${meetingProvider.deviceList[i]} was chosen.");
            Navigator.pop(context, meetingProvider.deviceList[i]);
          },
        ),
      );
    }
    return dialogOptions;
  }

  IconData localMuteIcon(MeetingViewModel meetingProvider) {
    if (!meetingProvider
        .currAttendees[meetingProvider.localAttendeeId]!.muteStatus) {
      return Icons.mic;
    } else {
      return Icons.mic_off;
    }
  }

  IconData remoteMuteIcon(MeetingViewModel meetingProvider) {
    if (!meetingProvider
        .currAttendees[meetingProvider.remoteAttendeeId]!.muteStatus) {
      return Icons.mic;
    } else {
      return Icons.mic_off;
    }
  }

  IconData localVideoIcon(MeetingViewModel meetingProvider) {
    if (meetingProvider
        .currAttendees[meetingProvider.localAttendeeId]!.isVideoOn) {
      return Icons.videocam;
    } else {
      return Icons.videocam_off;
    }
  }

  IconData remoteVideoIcon(MeetingViewModel meetingProvider) {
    if (meetingProvider
        .currAttendees[meetingProvider.remoteAttendeeId]!.isVideoOn) {
      return Icons.videocam;
    } else {
      return Icons.videocam_off;
    }
  }
}
