import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mvp_chime_flutter/method_channel_coordinator.dart';
import 'package:provider/provider.dart';

import '../view_models/join_meeting_view_model.dart';
import '../view_models/meeting_view_model.dart';

class JoinMeetingView extends StatelessWidget {
  JoinMeetingView({super.key, this.tokenCall});

  final String? tokenCall;
  final TextEditingController hashRoomTEC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final joinMeetingProvider = Provider.of<JoinMeetingViewModel>(context);
    final methodChannelProvider =
        Provider.of<MethodChannelCoordinator>(context);
    final meetingProvider = Provider.of<MeetingViewModel>(context);

    final orientation = MediaQuery.of(context).orientation;

    hashRoomTEC.value = TextEditingValue(text: (tokenCall ?? '').trim());

    return joinMeetingBody(
      joinMeetingProvider,
      methodChannelProvider,
      meetingProvider,
      context,
      orientation,
    );
  }

//
// —————————————————————————— Main Body ——————————————————————————————————————
//

  Widget joinMeetingBody(
      JoinMeetingViewModel joinMeetingProvider,
      MethodChannelCoordinator methodChannelProvider,
      MeetingViewModel meetingProvider,
      BuildContext context,
      Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return joinMeetingBodyPortrait(
        joinMeetingProvider,
        methodChannelProvider,
        meetingProvider,
        context,
      );
    } else {
      return joinMeetingBodyLandscape(
        joinMeetingProvider,
        methodChannelProvider,
        meetingProvider,
        context,
      );
    }
  }

//
// —————————————————————————— Portrait Body ——————————————————————————————————————
//

  Widget joinMeetingBodyPortrait(
      JoinMeetingViewModel joinMeetingProvider,
      MethodChannelCoordinator methodChannelProvider,
      MeetingViewModel meetingProvider,
      BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.withAlpha(500),
                Colors.greenAccent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                titleFlutterDemo(5),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 10,
                  ),
                  child: hashRoomTextField(hashRoomTEC),
                ),
                joinButton(
                  joinMeetingProvider,
                  methodChannelProvider,
                  meetingProvider,
                  context,
                ),
                loadingIcon(joinMeetingProvider),
                errorMessage(joinMeetingProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

//
// —————————————————————————— Landscape Body ——————————————————————————————————————
//

  Widget joinMeetingBodyLandscape(
      JoinMeetingViewModel joinMeetingProvider,
      MethodChannelCoordinator methodChannelProvider,
      MeetingViewModel meetingProvider,
      BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 60,
              ),
              titleFlutterDemo(10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                child: hashRoomTextField(hashRoomTEC),
              ),
              joinButton(joinMeetingProvider, methodChannelProvider,
                  meetingProvider, context),
              loadingIcon(joinMeetingProvider),
              errorMessage(joinMeetingProvider),
            ],
          ),
        ),
      ),
    );
  }

//
// —————————————————————————— Helpers ——————————————————————————————————————
//

  Widget joinButton(
      JoinMeetingViewModel joinMeetingProvider,
      MethodChannelCoordinator methodChannelProvider,
      MeetingViewModel meetingProvider,
      BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        "Entrar",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      onPressed: () async {
        // Hide Keyboard
        FocusManager.instance.primaryFocus?.unfocus();

        handleJoinMeeting(
          joinMeetingProvider,
          methodChannelProvider,
          meetingProvider,
          context,
        );
      },
    );
  }

  void handleJoinMeeting(
    JoinMeetingViewModel joinMeetingProvider,
    MethodChannelCoordinator methodChannelProvider,
    MeetingViewModel meetingProvider,
    BuildContext context,
  ) async {
    String hashRoomToConnect = tokenCall ?? hashRoomTEC.text;

    if (joinMeetingProvider.verifyParameters(hashRoomToConnect)) {
      joinMeetingProvider.joinButtonClicked = true;

      bool isMeetingJoined = await joinMeetingProvider.joinMeeting(
        meetingProvider,
        methodChannelProvider,
        hashRoomToConnect,
      );

      if (isMeetingJoined) {
        methodChannelProvider.initializeObservers(meetingProvider);
        methodChannelProvider.initializeMethodCallHandler();

        final lastDeviceAudio = meetingProvider.deviceList.last;

        if (lastDeviceAudio != null) {
          meetingProvider.updateCurrentDevice(lastDeviceAudio);
        }

        // ignore: use_build_context_synchronously
        context.go('/meeting');
      }
    }
    joinMeetingProvider.joinButtonClicked = false;
  }

  Widget titleFlutterDemo(double pad) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: pad),
      child: const Column(
        children: [
          Text(
            "Tele-consulta",
            style: TextStyle(
              fontSize: 40,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 82),
            child: Text(
              "Entre com o código da sala para ter sua consulta",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget hashRoomTextField(hashRoomTEC) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: hashRoomTEC,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          labelText: "Código da sala",
          labelStyle: TextStyle(
            color: Colors.white,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2, color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2, color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget loadingIcon(JoinMeetingViewModel joinMeetingProvider) {
    if (joinMeetingProvider.loadingStatus) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: CircularProgressIndicator());
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget errorMessage(JoinMeetingViewModel joinMeetingProvider) {
    if (joinMeetingProvider.error) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 56),
            child: Text(
              "${joinMeetingProvider.errorMessage}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color.fromARGB(255, 245, 97, 97),
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
