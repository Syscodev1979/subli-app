import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/club_config.dart';
import '../../feed/presentation/feed_palette.dart';

/// A profil alján a verzió és a visszajelző e-mail.
class ProfileFooter extends StatefulWidget {
  const ProfileFooter({super.key});

  @override
  State<ProfileFooter> createState() => _ProfileFooterState();
}

class _ProfileFooterState extends State<ProfileFooter> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    } catch (_) {
      // A widgettesztben nincs platformcsatorna.
    }
  }

  Future<void> _sendFeedback() async {
    final version = _version.isEmpty ? 'ismeretlen' : _version;
    final device = await _deviceLabel();
    final body = 'Verzió: $version\nKészülék: $device\n\n';
    final uri = Uri.parse(
      'mailto:${ClubConfig.feedbackEmail}'
      '?subject=${Uri.encodeComponent('Gastroyal visszajelzés $version')}'
      '&body=${Uri.encodeComponent(body)}',
    );
    await launchUrl(uri);
  }

  Future<String> _deviceLabel() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return '${info.model} (${info.utsname.machine}) · iOS ${info.systemVersion}';
      }
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return '${info.manufacturer} ${info.model} · Android ${info.version.release}';
      }
    } catch (_) {
      return Platform.operatingSystem;
    }
    return Platform.operatingSystem;
  }

  @override
  Widget build(BuildContext context) {
    final muted = FeedPalette.muted(context);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('Visszajelzés küldése'),
          onTap: _sendFeedback,
        ),
        if (_version.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _version,
              style: TextStyle(
                color: muted.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
