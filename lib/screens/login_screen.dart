import 'package:flutter/material.dart';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleLogoutTap(BuildContext context) async {
    await Amplify.Auth.signOut();
    if (context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log in'),
      ),
      body: AuthenticatedView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You are logged in!'),
              TextButton(
                onPressed: () => _handleLogoutTap(context),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
