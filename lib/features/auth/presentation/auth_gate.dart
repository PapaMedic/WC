import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/features/auth/data/auth_repository.dart';
import 'package:wildland_companion_v2/features/auth/presentation/auth_page.dart';
import 'package:wildland_companion_v2/features/auth/presentation/complete_profile_page.dart';
import 'package:wildland_companion_v2/features/auth/presentation/email_verification_page.dart';

class AuthGate extends StatefulWidget {
  final Widget authenticatedChild;

  const AuthGate({
    super.key,
    required this.authenticatedChild,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _profileRefreshKey = 0;

  void _refreshProfileState() {
    setState(() {
      _profileRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WildlandBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return FutureBuilder<bool>(
            key: ValueKey('profile-check-$_profileRefreshKey-${user.uid}'),
            future: authRepository.currentUserHasProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const WildlandBackground(
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                );
              }

              if (profileSnapshot.data != true) {
                return CompleteProfilePage(
                  onProfileCompleted: _refreshProfileState,
                );
              }

              if (user.emailVerified) {
                return widget.authenticatedChild;
              }

              return EmailVerificationPage(email: user.email ?? 'your email');
            },
          );
        }

        return const AuthPage();
      },
    );
  }
}
