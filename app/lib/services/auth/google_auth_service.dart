import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class GoogleAuthAccount {
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;
  final String? accessToken;

  const GoogleAuthAccount({
    required this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
    this.accessToken,
  });
}

class GoogleAuthCancelledException implements Exception {
  const GoogleAuthCancelledException();
}

class GoogleAuthException implements Exception {
  final String message;

  const GoogleAuthException(this.message);

  @override
  String toString() => 'GoogleAuthException: $message';
}

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn =
            googleSignIn ?? GoogleSignIn.standard(scopes: ['email']);

  Future<GoogleAuthAccount> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const GoogleAuthCancelledException();
      }
      final authentication = await account.authentication;

      return GoogleAuthAccount(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        idToken: authentication.idToken,
        accessToken: authentication.accessToken,
      );
    } on GoogleAuthCancelledException {
      rethrow;
    } on PlatformException catch (error) {
      throw GoogleAuthException(_mapGooglePlatformError(error));
    } catch (_) {
      throw const GoogleAuthException(
        'Não foi possível autenticar com o Google. Verifique a configuração do app e tente novamente.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
  }

  String _mapGooglePlatformError(PlatformException error) {
    final code = error.code.toLowerCase();

    if (code.contains('network')) {
      return 'Falha de rede ao autenticar com o Google. Confira sua conexão e tente novamente.';
    }
    if (code.contains('sign_in_failed') ||
        code.contains('api_exception') ||
        code.contains('10')) {
      return 'Falha de configuração do Google Sign-In (Android). Verifique package name, SHA-1 e client OAuth no Firebase/Google Cloud.';
    }

    return 'Não foi possível autenticar com o Google (${error.code}). Detalhe: ${error.message ?? 'sem detalhe'}';
  }
}
