import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:telemed_neurondata/view_models/join_meeting_view_model.dart';
import 'package:telemed_neurondata/view_models/meeting_view_model.dart';
import 'package:telemed_neurondata/views/join_meeting.dart';
import 'package:telemed_neurondata/views/meeting.dart';
import 'package:telemed_neurondata/views/thanks.dart';

import 'method_channel_coordinator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MethodChannelCoordinator()),
        ChangeNotifierProvider(create: (_) => JoinMeetingViewModel()),
        ChangeNotifierProvider(create: (context) => MeetingViewModel(context)),
      ],
      child: GestureDetector(
        onTap: () {
          // Unfocus keyboard when tapping on non-clickable widget
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: MaterialApp.router(
          title: 'Telemed - MVP',
          debugShowCheckedModeBanner: false,
          routerConfig: GoRouter(
            initialLocation: '/',
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => JoinMeetingView(),
              ),
              GoRoute(
                path: '/thanks',
                builder: (context, state) => const ThanksView(),
              ),
              GoRoute(
                path: '/room/:tokenCall',
                builder: (context, state) {
                  String? tokenCall = state.pathParameters['tokenCall'];
                  return JoinMeetingView(tokenCall: tokenCall);
                },
              ),
              GoRoute(path: '/meeting', builder: (_, __) => MeetingView())
            ],
          ),
        ),
      ),
    );
  }
}
