import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/app_router.dart';
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';
import 'package:wildland_companion_v2/core/repositories/user_repository.dart';
import 'package:wildland_companion_v2/core/services/firebase/firebase_bootstrap.dart';
import 'package:wildland_companion_v2/features/auth/account_setup_page.dart';
import 'package:wildland_companion_v2/features/auth/login_page.dart';
import 'package:wildland_companion_v2/features/auth/services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isInitialized) {
      return const AppRouter();
    }

    return StreamBuilder<firebase_auth.User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoading();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const LoginPage();
        }

        return StreamBuilder<AppUser?>(
          stream: UserRepository().watchUser(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoading();
            }

            final appUser = userSnapshot.data;
            if (appUser == null || !appUser.hasProfile) {
              return AccountSetupPage(firebaseUser: firebaseUser);
            }

            return Provider<AppUser>.value(
              value: appUser,
              child: const AppRouter(),
            );
          },
        );
      },
    );
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
