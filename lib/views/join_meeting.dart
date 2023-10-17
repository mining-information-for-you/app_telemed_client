import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:telemed_neurondata/method_channel_coordinator.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

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
    final size = MediaQuery.of(context).size;

    final maskFormatter = MaskTextInputFormatter(
      mask: '###-###',
      filter: {"#": RegExp(r'[0-9a-zA-Z]')},
      type: MaskAutoCompletionType.lazy,
    );

    hashRoomTEC.value = TextEditingValue(text: (tokenCall ?? '').trim());

    return Scaffold(
      body: Stack(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF92ABFB),
                  Color(0xFF3360F6),
                ],
              ),
            ),
            child: Image.asset('assets/background.png'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Image.asset('assets/logo.png'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "Tele-Consulta",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Formulários
                Column(
                  children: [
                    TextField(
                      controller: hashRoomTEC,
                      inputFormatters: [maskFormatter],
                      style: const TextStyle(
                        color: Color(0xFF2a2a2a),
                      ),
                      decoration: const InputDecoration(
                        labelText: "Código da sala",
                        labelStyle: TextStyle(
                          color: Colors.grey,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        floatingLabelStyle: TextStyle(
                          color: Colors.white,
                        ),
                        filled: true,
                        fillColor: Colors.white,
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
                    const SizedBox(
                      height: 24,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBEAFB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        // Hide Keyboard
                        FocusManager.instance.primaryFocus?.unfocus();

                        if (joinMeetingProvider.loadingStatus == false) {
                          handleJoinMeeting(
                            joinMeetingProvider,
                            methodChannelProvider,
                            meetingProvider,
                            context,
                          );
                        }
                      },
                      child: joinMeetingProvider.loadingStatus
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Color(0xFF2a2a2a),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Entrar",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF2a2a2a),
                              ),
                            ),
                    ),
                  ],
                ),

                // Footer
                const Text(
                  'www.neurondata.com.br',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
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

        meetingProvider.toggleLocalOutputAudio();

        // ignore: use_build_context_synchronously
        context.go('/meeting');
      }
    }
    joinMeetingProvider.joinButtonClicked = false;
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
