import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/features/auth/data/auth_repository.dart';
import 'package:wildland_companion_v2/features/auth/presentation/auth_page.dart';

class AuthGate extends StatelessWidget {
  final Widget authenticatedChild;

  const AuthGate({
    super.key,
    required this.authenticatedChild,
  });

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

        if (snapshot.hasData) {
          return authenticatedChild;
        }

        return const AuthPage();
      },
    );
  }
}
