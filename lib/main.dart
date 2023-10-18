import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './amplify.dart';
import './models/Workout.dart';
import './screens/login_screen.dart';
import './screens/details_screen.dart';
import './screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // If there are errors, try in initState() instead
  await configureAmplify();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // GoRouter configuration
  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const HomeScreen(title: 'Flutter Demo Home Page'),
      ),
      GoRoute(
        path: '/workout/:id',
        builder: (context, state) {
          // final id = state.pathParameters['id'];
          final extra = state.extra as Map;
          final workout = extra['workout'] as Workout;
          final workoutNumber = extra['workoutNumber'] as int;
          return DetailsScreen(
            workout: workout,
            workoutNumber: workoutNumber,
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp.router(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
