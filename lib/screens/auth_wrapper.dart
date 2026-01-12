import 'package:firebase_auth/firebase_auth.dart'; // Required for StreamBuilder
import 'package:flutter/material.dart';
import 'package:entry_kit/entry_kit.dart';
import 'package:stress_detection_app/core/theme.dart';
import 'package:stress_detection_app/repositories/mental_health_auth_repo.dart';
import 'package:stress_detection_app/screens/main_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. REACTIVE STATE MANAGEMENT
    // This stream listens for login/logout events in real-time.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // A. Initial Check (Loading from disk)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundIce,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
          );
        }

        // B. User is Authenticated -> Go Straight to App
        if (snapshot.hasData) {
          return const MainShell();
        }

        // C. User is Logged Out -> Show EntryKit
        return _buildLoginView(context);
      },
    );
  }

  Widget _buildLoginView(BuildContext context) {
    return LoginView(
      authRepository: MentalHealthAuthRepo(),

      // Theme Integration
      theme: const LoginTheme(
        primaryColor: AppTheme.primaryTeal,
        backgroundColor: Color(0xFFF0F4F4),
        inputFillColor: Colors.white,
        inputBorderRadius: 24.0,
        titleStyle: TextStyle(
          color: AppTheme.textDark,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // Text Configuration
      texts: const LoginTexts(
        loginButton: "Begin Session",
        emailLabel: "Email Address",
        emailError: "Please enter your email",
        forgotPasswordTitle: "Recover Access",
        resetLinkSentMessage: "We've sent a recovery link to your email.",
      ),

      // Features
      enableGoogleAuth: true,
      enableAppleAuth: false,

      logo: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.self_improvement,
          size: 60,
          color: AppTheme.primaryTeal,
        ),
      ),

      // NAVIGATION LOGIC
      // Note: onLoginSuccess is empty because the StreamBuilder above
      // handles the navigation automatically when the auth state changes.
      onLoginSuccess: () {},

      onSignUp: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const SignUpScreenWrapper(),
        ));
      },
      onForgotPassword: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ForgotPasswordWrapper(),
        ));
      },
    );
  }
}

class SignUpScreenWrapper extends StatelessWidget {
  const SignUpScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SignUpView(
      authRepository: MentalHealthAuthRepo(),

      passwordConfig: const PasswordConfig(
        minLength: 8,
        requireUppercase: true,
        requireDigit: true,
        requireSpecialChar: true,
      ),

      theme: const LoginTheme(
        primaryColor: AppTheme.primaryTeal,
        backgroundColor: Color(0xFFF0F4F4),
        inputFillColor: Colors.white,
        inputBorderRadius: 24.0,
      ),

      texts: const LoginTexts(
        createAccountButton: "Create Secure Space",
      ),

      onSignUpSuccess: () {
        // Close this screen. The AuthWrapper stream will detect the new user
        // and show the MainShell automatically.
        Navigator.of(context).pop();
      },
      onLoginTap: () => Navigator.of(context).pop(),
    );
  }
}

class ForgotPasswordWrapper extends StatelessWidget {
  const ForgotPasswordWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordView(
      authRepository: MentalHealthAuthRepo(),
      theme: const LoginTheme(
        primaryColor: AppTheme.primaryTeal,
        backgroundColor: Color(0xFFF0F4F4),
        inputFillColor: Colors.white,
        inputBorderRadius: 24.0,
      ),
      onBackToLogin: () => Navigator.of(context).pop(),
    );
  }
}