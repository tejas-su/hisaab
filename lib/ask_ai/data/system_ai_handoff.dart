import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/ai_handoff.dart';

/// [AiHandoff] over the platform clipboard, `url_launcher` and the `share_plus` share sheet.
final class SystemAiHandoff implements AiHandoff {
  const SystemAiHandoff();

  @override
  Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));

  @override
  Future<bool> open(Uri link) async {
    try {
      return await launchUrl(link, mode: LaunchMode.externalApplication);
    } on PlatformException {
      // why: no app can open the link; the text is already copied, so the caller falls back to
      // the "paste it" toast instead of failing.
      return false;
    }
  }

  @override
  Future<void> share(String text) => SharePlus.instance.share(ShareParams(text: text));
}
