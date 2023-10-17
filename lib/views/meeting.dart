import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:telemed_neurondata/view_models/meeting_view_model.dart';
import 'package:telemed_neurondata/views/screenshare.dart';
import 'package:provider/provider.dart';
import 'package:telemed_neurondata/views/thanks.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../logger.dart';

// ignore: must_be_immutable
class MeetingView extends StatelessWidget {
  MeetingView({Key? key}) : super(key: key);

  List<Widget>? listVideoTiles;

  Widget? localVideoTile;

  @override
  Widget build(BuildContext context) {
    final meetingProvider = Provider.of<MeetingViewModel>(context);
    final orientation = MediaQuery.of(context).orientation;
    final size = MediaQuery.of(context).size;

    if (!meetingProvider.isMeetingActive) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const ThanksView()));
    }

    displayVideoTiles(
      meetingProvider,
      orientation,
      context,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Stack(
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
                children: [
                  ...listVideoTiles ?? [],
                  localVideoTile ?? const SizedBox(height: 0)
                ],
              ),
            ),
            displayActionsAttendeeLocal(meetingProvider, context),
          ],
        ),
      ),
    );
  }

  Widget displayActionsAttendeeLocal(
    MeetingViewModel meetingProvider,
    BuildContext context,
  ) {
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
        color: Colors.white.withAlpha(145),
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
              context.replace('/thanks');
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
            icon: Icon(audioOutputIcon(meetingProvider)),
            iconSize: 28,
            constraints: const BoxConstraints(),
            color: Colors.blue,
            onPressed: () {
              meetingProvider.toggleLocalOutputAudio();
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
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MeetingView()));
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
                                builder: (context) => MeetingView())),
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

  void displayVideoTiles(
    MeetingViewModel meetingProvider,
    Orientation orientation,
    BuildContext context,
  ) {
    if (meetingProvider
            .currAttendees[meetingProvider.localAttendeeId]?.isVideoOn ??
        false) {
      if (meetingProvider
              .currAttendees[meetingProvider.localAttendeeId]?.videoTile !=
          null) {
        localVideoTile = videoTile(
          meetingProvider,
          context,
          isContent: false,
          videoTileId: meetingProvider
              .currAttendees[meetingProvider.localAttendeeId]!
              .videoTile!
              .tileId,
        );
      } else {
        localVideoTile = null;
      }
    } else {
      localVideoTile = null;
    }

    if (meetingProvider.currAttendees
        .containsKey(meetingProvider.contentAttendeeId)) {
      if (meetingProvider.isReceivingScreenShare) {
        if (meetingProvider.contentAttendeeId != null) {
          if (meetingProvider.currAttendees[meetingProvider.contentAttendeeId]
                  ?.videoTile !=
              null) {
            listVideoTiles = [
              videoTile(
                meetingProvider,
                context,
                isContent: true,
                videoTileId: meetingProvider
                    .currAttendees[meetingProvider.contentAttendeeId]
                    ?.videoTile
                    ?.tileId as int,
              )
            ];
          }
        }
        return;
      }
    }

    List<Widget> videoTiles = [];

    if (meetingProvider.currAttendees.length > 1) {
      meetingProvider.currAttendees.forEach(
        (key, attendee) {
          if (attendee.attendeeId != meetingProvider.localAttendeeId) {
            if (attendee.isVideoOn) {
              if (attendee.videoTile != null) {
                videoTiles.add(
                  Expanded(
                    key: Key(attendee.videoTile!.tileId.toString()),
                    child: videoTile(
                      meetingProvider,
                      context,
                      isContent: false,
                      videoTileId: attendee.videoTile!.tileId,
                    ),
                  ),
                );
              }
            }
          }
        },
      );
    }

    Widget? emptyVideos;

    if (meetingProvider.currAttendees.length <= 1) {
      emptyVideos = Expanded(
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/video_empty.svg',
                width: 262,
                height: 262,
              ),
              const SizedBox(
                height: 32,
              ),
              const Text(
                "Sem participantes",
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (videoTiles.isEmpty) {
      emptyVideos = Expanded(
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/conversation.svg',
                width: 192,
                height: 192,
              ),
            ],
          ),
        ),
      );
    }
    if (emptyVideos != null) {
      listVideoTiles = [emptyVideos];
    } else {
      listVideoTiles = videoTiles;
    }
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

  Widget videoTile(
    MeetingViewModel meetingProvider,
    BuildContext context, {
    required bool isContent,
    required int videoTileId,
  }) {
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
    } else {
      paramsVT = videoTileId;
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

  IconData audioOutputIcon(MeetingViewModel meetingProvider) {
    final changedAudio = meetingProvider.changedSelectedAudioDevice == true;
    if (changedAudio) {
      return Icons.spatial_audio_off;
    } else {
      return Icons.volume_up;
    }
  }
}
