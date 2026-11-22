import 'package:auth_notification_app/core/session/session_manager.dart';
import 'package:auth_notification_app/core/utils/date_formatter.dart';
import 'package:auth_notification_app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:auth_notification_app/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:auth_notification_app/features/auth/presentation/widgets/info_card.dart';
import 'package:auth_notification_app/features/auth/presentation/widgets/mock_deep_link_button.dart';
import 'package:auth_notification_app/features/auth/presentation/widgets/status_card.dart';
import 'package:auth_notification_app/features/auth/presentation/widgets/welcome_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  final SessionManager sessionManager;
  final bool Function(Uri uri) onDeepLink;

  const HomeView({
    super.key,
    required this.sessionManager,
    required this.onDeepLink,
  });

  static const Color primaryColor = Color(0xFF1E293B);
  static const Color accentColor = Color(0xFF0D9488);
  @override
  Widget build(BuildContext context) {
    final session = sessionManager.currentSession;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () => context.read<AuthCubit>().logout(),
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded, color: primaryColor),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeSection(),
              const SizedBox(height: 28),
              const Text(
                'Account Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              StatusCard(isSessionValid: sessionManager.hasValidSession),
              const SizedBox(height: 24),
              const Text(
                'Session Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              if (session != null) ...[
                InfoCard(
                  title: 'Session Expires At',
                  value: formatDate(session.expiresAt),
                  icon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 12),
                InfoCard(
                  title: 'Access Token',
                  value: 'Available',
                  icon: Icons.key_rounded,
                ),
                const SizedBox(height: 12),
                InfoCard(
                  title: 'Refresh Token',
                  value: 'Secured',
                  icon: Icons.lock_outline_rounded,
                ),
              ] else
                const Text('No active session found.'),
              const SizedBox(height: 28),
              MockDeepLinkButton(
                onPressed: () {
                  final accepted = onDeepLink(
                    Uri.parse('myapp://approval/request_001'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        accepted
                            ? 'Approval link received.'
                            : 'Invalid approval link.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
