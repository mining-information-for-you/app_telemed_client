import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:telemed_neurondata/method_channel_coordinator.dart';

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
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SvgPicture.asset(
                  'assets/logo-ha.svg',
                  height: 92,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    "Tele-Consulta",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0064C6),
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
                    color: Color(0xFF0064C6),
                  ),
                  decoration: const InputDecoration(
                    labelText: "Código da sala",
                    labelStyle: TextStyle(
                      color: Color(0xFF0064C6),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    floatingLabelStyle: TextStyle(
                      color: Colors.white,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 1, color: Color(0xFF0064C6)),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 1, color: Color(0xFF0064C6)),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0064C6),
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
                            color: Color(0xFFEBEAFB),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Entrar",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFFEBEAFB),
                          ),
                        ),
                ),
              ],
            ),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Powered by',
                  style: TextStyle(
                    color: Color(0xFF0064C6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Image.asset(
                  'assets/logo.png',
                  height: 28,
                ),
              ],
            )
          ],
        ),
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
      } else {
        // ignore: use_build_context_synchronously
        errorMessage(joinMeetingProvider, context);
      }
    } else {
      errorMessage(joinMeetingProvider, context);
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

  void errorMessage(
      JoinMeetingViewModel joinMeetingProvider, BuildContext context) {
    if (joinMeetingProvider.error) {
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Ops!',
          message:
              'Não foi possível conectar, solicite um novo código e tente novamente!',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }
}
