import 'package:url_launcher/url_launcher.dart';

class ContactService {
  ContactService._();

  static Future<bool> callPhone(String phone) {
    final normalized = _phoneForCall(phone);
    if (normalized == null) return Future.value(false);

    return launchUrl(
      Uri(scheme: 'tel', path: normalized),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) {
    final normalized = _phoneForWhatsApp(phone);
    if (normalized == null) return Future.value(false);

    final uri = Uri.https('wa.me', '/$normalized', {'text': message});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String? _phoneForCall(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static String? _phoneForWhatsApp(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('57')) return digits;
    if (digits.length == 10) return '57$digits';
    return digits;
  }
}
