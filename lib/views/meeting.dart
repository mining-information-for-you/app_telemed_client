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

class MeetingView extends StatefulWidget {
  const MeetingView({Key? key}) : super(key: key);

  @override
  State<MeetingView> createState() => _MeetingViewState();
}

class _MeetingViewState extends State<MeetingView> {
  List<Widget> listVideoTiles = [];

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
  Widget meetingBodyPortrait(MeetingViewModel meetingProvider,
      Orientation orientation, BuildContext context) {
    final size = MediaQuery.of(context).size;

    displayVideoTiles(
      meetingProvider,
      orientation,
      context,
    );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        WillPopScope(
          onWillPop: () async {
            meetingProvider.stopMeeting();
            return true;
          },
          child: const SizedBox(height: 0),
        ),
        SizedBox(
          height: size.height,
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: listVideoTiles,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(175),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.phone_disabled),
            iconSize: 28,
            color: Colors.red,
            onPressed: () {
              meetingProvider.stopMeeting();
              Navigator.pop(context);
            },
          ),
          const SizedBox(
            width: 16,
          ),
          IconButton(
            icon: Icon(localMuteIcon(meetingProvider)),
            iconSize: 28,
            color: Colors.blue,
            onPressed: () {
              meetingProvider.sendLocalMuteToggle();
            },
          ),
          const SizedBox(
            width: 16,
          ),
          IconButton(
            icon: Icon(localVideoIcon(meetingProvider)),
            iconSize: 28,
            constraints: const BoxConstraints(),
            color: Colors.blue,
            onPressed: () {
              meetingProvider.sendLocalVideoTileOn();
            },
          ),
          const SizedBox(
            width: 16,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            iconSize: 28,
            constraints: const BoxConstraints(),
            color: Colors.blue,
            onPressed: () {
              meetingProvider.toggleLocalVideoTile();
            },
          ),
        ],
      ),
    );
  }

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

  void displayVideoTiles(MeetingViewModel meetingProvider,
      Orientation orientation, BuildContext context) {
    Widget screenShareWidget = Container(
      child: videoTile(
        meetingProvider,
        context,
        isLocal: false,
        isContent: true,
      ),
    );
    Widget localVideoTile = Expanded(
      child: FittedBox(
        fit: BoxFit.cover,
        child: videoTile(
          meetingProvider,
          context,
          isLocal: true,
          isContent: false,
        ),
      ),
    );
    Widget remoteVideoTile = Expanded(
      child: FittedBox(
        fit: BoxFit.cover,
        child: videoTile(
          meetingProvider,
          context,
          isLocal: false,
          isContent: false,
        ),
      ),
    );

    if (meetingProvider.currAttendees
        .containsKey(meetingProvider.contentAttendeeId)) {
      if (meetingProvider.isReceivingScreenShare) {
        setState(() {
          listVideoTiles = [screenShareWidget];
        });
        return;
      }
    }

    List<Widget> videoTiles = [];
    List<String> videoTilesAttendeeId = [];

    final onAddRemoteVideoTile = (meetingProvider.remoteAttendeeId) != null &&
        (meetingProvider.currAttendees
            .containsKey(meetingProvider.remoteAttendeeId)) &&
        (meetingProvider
                .currAttendees[meetingProvider.remoteAttendeeId]?.isVideoOn ??
            false) &&
        (meetingProvider
                .currAttendees[meetingProvider.remoteAttendeeId]?.videoTile !=
            null) &&
        (!videoTilesAttendeeId
            .any((id) => id.contains(meetingProvider.remoteAttendeeId!)));

    final onAddLocalVideoTile = (meetingProvider
                .currAttendees[meetingProvider.localAttendeeId]?.isVideoOn ??
            false) &&
        (meetingProvider
                .currAttendees[meetingProvider.localAttendeeId]?.videoTile !=
            null) &&
        (!videoTilesAttendeeId
            .any((id) => id.contains(meetingProvider.localAttendeeId!)));

    if (onAddRemoteVideoTile) {
      videoTilesAttendeeId.add(meetingProvider.remoteAttendeeId!);
      videoTiles.add(remoteVideoTile);
    }

    if (onAddLocalVideoTile) {
      videoTilesAttendeeId.add(meetingProvider.localAttendeeId!);
      videoTiles.add(localVideoTile);
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

    setState(() {
      listVideoTiles = videoTiles;
    });
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

  IconData localVideoIcon(MeetingViewModel meetingProvider) {
    if (meetingProvider
        .currAttendees[meetingProvider.localAttendeeId]!.isVideoOn) {
      return Icons.videocam;
    } else {
      return Icons.videocam_off;
    }
  }
}
