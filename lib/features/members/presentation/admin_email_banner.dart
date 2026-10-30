import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/admin_identity.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/auth_error_message.dart';

/// Bordó sáv, amíg a kijelölt admin e-mailje nincs megerősítve.
class AdminEmailBanner extends ConsumerStatefulWidget {
  const AdminEmailBanner({super.key});

  @override
  ConsumerState<AdminEmailBanner> createState() => _AdminEmailBannerState();
}

class _AdminEmailBannerState extends ConsumerState<AdminEmailBanner> {
  var _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Megerősítő e-mail elküldve.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reload() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).reloadCurrentUser();
      final session = ref.read(authGateProvider).asData?.value;
      final verified = session is AuthSignedIn && session.emailVerified;
      if (mounted && !verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Az e-mail cím még nincs megerősítve.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.burgundy,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Az admin jogokhoz erősítsd meg az e-mail címed',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _send,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onPrimary,
                    side: const BorderSide(color: AppColors.onPrimary),
                  ),
                  child: const Text('Megerősítő e-mail küldése'),
                ),
                FilledButton(
                  onPressed: _busy ? null : _reload,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.onPrimary,
                    foregroundColor: AppColors.burgundy,
                  ),
                  child: const Text('Már megerősítettem'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool sessionNeedsAdminVerification(AuthSession? session) {
  if (session is! AuthSignedIn) return false;
  return needsAdminEmailVerification(
    email: session.identityEmail,
    emailVerified: session.emailVerified,
  );
}
