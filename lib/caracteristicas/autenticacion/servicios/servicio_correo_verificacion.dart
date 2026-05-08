import 'package:book_manager/datos/api/api_client.dart';

class VerificationEmailService {
  VerificationEmailService._();

  static final VerificationEmailService instance = VerificationEmailService._();

  final ApiClient _api = ApiClient.instance;

  Future<void> sendCode({
    required String email,
    required String code,
  }) async {
    await _api.post('/api/v1/auth/send-verification-code', {
      'email': email,
      'code': code,
    });
  }
}
