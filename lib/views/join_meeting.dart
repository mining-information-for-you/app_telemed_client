import 'package:flutter/material.dart';
import 'package:mvp_chime_flutter/method_channel_coordinator.dart';
import 'package:provider/provider.dart';

import '../view_models/join_meeting_view_model.dart';
import '../view_models/meeting_view_model.dart';
import 'meeting.dart';

class JoinMeetingView extends StatelessWidget {
  JoinMeetingView({Key? key}) : super(key: key);

  final TextEditingController hashRoomTEC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final joinMeetingProvider = Provider.of<JoinMeetingViewModel>(context);
    final methodChannelProvider =
        Provider.of<MethodChannelCoordinator>(context);
    final meetingProvider = Provider.of<MeetingViewModel>(context);

    final orientation = MediaQuery.of(context).orientation;

    return joinMeetingBody(joinMeetingProvider, methodChannelProvider,
        meetingProvider, context, orientation);
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
          joinMeetingProvider, methodChannelProvider, meetingProvider, context);
    } else {
      return joinMeetingBodyLandscape(
          joinMeetingProvider, methodChannelProvider, meetingProvider, context);
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
      appBar: AppBar(
        title: const Text('MI4U'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            titleFlutterDemo(5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              child: hashRoomTextField(hashRoomTEC),
            ),
            joinButton(joinMeetingProvider, methodChannelProvider,
                meetingProvider, context),
            loadingIcon(joinMeetingProvider),
            errorMessage(joinMeetingProvider),
          ],
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
      child: const Text("Entrar"),
      onPressed: () async {
        if (!joinMeetingProvider.joinButtonClicked) {
          // Prevent multiple clicks
          joinMeetingProvider.joinButtonClicked = true;

          // Hide Keyboard
          FocusManager.instance.primaryFocus?.unfocus();

          String hashRoom = hashRoomTEC.text.trim();

          if (joinMeetingProvider.verifyParameters(hashRoom)) {
            // Observers should be initialized before MethodCallHandler
            methodChannelProvider.initializeObservers(meetingProvider);
            methodChannelProvider.initializeMethodCallHandler();

            // Call api, format to JSON and send to native
            bool isMeetingJoined = await joinMeetingProvider.joinMeeting(
                meetingProvider, methodChannelProvider, hashRoom);
            if (isMeetingJoined) {
              final lastDeviceAudio = meetingProvider.deviceList.last;

              if (lastDeviceAudio != null) {
                meetingProvider.updateCurrentDevice(lastDeviceAudio);
              }
              // ignore: use_build_context_synchronously
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeetingView(),
                ),
              );
            }
          }
          joinMeetingProvider.joinButtonClicked = false;
        }
      },
    );
  }

  Widget titleFlutterDemo(double pad) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: pad),
      child: const Text(
        "Telemed",
        style: TextStyle(
          fontSize: 32,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget hashRoomTextField(hashRoomTEC) {
    return TextField(
      controller: hashRoomTEC,
      decoration: const InputDecoration(
        labelText: "Código da sala",
        border: OutlineInputBorder(),
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
            padding: const EdgeInsets.all(15),
            child: Text(
              "${joinMeetingProvider.errorMessage}",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
