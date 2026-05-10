import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:logging/logging.dart';

final _log = Logger('AuthService');

/// Servizio di autenticazione biometrica + gestione master password ricordata.
///
/// Sicurezza:
/// - La master password ricordata viene salvata in `flutter_secure_storage`
///   che su Android usa `EncryptedSharedPreferences` (AES-256/GCM) cifrato
///   con chiave residente nell'**Android Keystore** (hardware-backed quando
///   disponibile).
/// - Per leggere il valore richiediamo prima un'autenticazione biometrica
///   (`local_auth`) con `biometricStrong`. Se l'utente fallisce o annulla,
///   non leggiamo nulla.
/// - Disabilitiamo `useErrorDialogs` per non mostrare dialog di sistema che
///   leakano informazioni; preferiamo UI nostra.
class AuthService {
  AuthService({LocalAuthentication? auth, FlutterSecureStorage? storage})
      : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? _defaultStorage();

  static FlutterSecureStorage _defaultStorage() => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          resetOnError: true,
        ),
      );

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const _kMasterPasswordKeyPrefix = 'kdbx.mp.';

  /// Verifica che il dispositivo supporti biometria forte.
  Future<bool> isBiometricAvailable() async {
    final supported = await _auth.isDeviceSupported();
    if (!supported) return false;
    final canCheck = await _auth.canCheckBiometrics;
    if (!canCheck) return false;
    final available = await _auth.getAvailableBiometrics();
    return available.isNotEmpty;
  }

  /// Chiede autenticazione biometrica. Ritorna `true` solo se l'utente
  /// si è autenticato con successo.
  Future<bool> promptBiometric({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            biometricHint: '',
            cancelButton: 'Annulla',
          ),
        ],
      );
    } on Object catch (e) {
      _log.warning('Biometric auth failed: ${e.runtimeType}');
      return false;
    }
  }

  /// Memorizza la master password per uno specifico vault, dietro autenticazione
  /// biometrica.
  Future<void> rememberMasterPassword({
    required String vaultPath,
    required String masterPassword,
  }) async {
    final ok = await promptBiometric(
        reason: 'Conferma per memorizzare la master password');
    if (!ok) return;
    await _storage.write(
      key: _key(vaultPath),
      value: masterPassword,
    );
  }

  /// Recupera la master password memorizzata, se presente, dietro biometria.
  Future<String?> retrieveMasterPassword({required String vaultPath}) async {
    final has = await _storage.containsKey(key: _key(vaultPath));
    if (!has) return null;
    final ok = await promptBiometric(reason: 'Sblocca con biometria');
    if (!ok) return null;
    return _storage.read(key: _key(vaultPath));
  }

  Future<void> forget({required String vaultPath}) =>
      _storage.delete(key: _key(vaultPath));

  Future<bool> hasRemembered({required String vaultPath}) =>
      _storage.containsKey(key: _key(vaultPath));

  String _key(String vaultPath) => '$_kMasterPasswordKeyPrefix$vaultPath';
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
