import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app;
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'cached_user';

  final ApiService _api;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthService(this._api);

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveTokens(String token, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<app.User> login(String email, String password) async {
    final response = await _api.login(email, password);
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      await saveTokens(
        data['token']?.toString() ?? '',
        data['refreshToken']?.toString(),
      );
      final user = app.User.fromJson(data['user'] as Map<String, dynamic>);
      await _cacheUser(user);
      return user;
    }
    throw response['error']?.toString() ?? 'Login failed';
  }

  Future<app.User> register(String username, String email, String password) async {
    final response = await _api.register(username, email, password);
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      await saveTokens(
        data['token']?.toString() ?? '',
        data['refreshToken']?.toString(),
      );
      final user = app.User.fromJson(data['user'] as Map<String, dynamic>);
      await _cacheUser(user);
      return user;
    }
    throw response['error']?.toString() ?? 'Registration failed';
  }

  Future<app.User> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'Google sign-in was cancelled';

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw 'Failed to get ID token';

      final response = await _api.googleSignIn(idToken);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        await saveTokens(
          data['token']?.toString() ?? '',
          data['refreshToken']?.toString(),
        );
        final user = app.User.fromJson(data['user'] as Map<String, dynamic>);
        await _cacheUser(user);
        return user;
      }
      throw response['error']?.toString() ?? 'Google sign-in failed';
    } catch (e) {
      rethrow;
    }
  }

  Future<app.User> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = fb.OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw 'Failed to get Apple ID token';

      final response = await _api.appleSignIn(
        identityToken: idToken,
        givenName: appleCredential.givenName,
        familyName: appleCredential.familyName,
      );
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        await saveTokens(
          data['token']?.toString() ?? '',
          data['refreshToken']?.toString(),
        );
        final user = app.User.fromJson(data['user'] as Map<String, dynamic>);
        await _cacheUser(user);
        return user;
      }
      throw response['error']?.toString() ?? 'Apple sign-in failed';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}
    await clearTokens();
  }

  Future<app.User?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      final data = jsonDecode(userJson) as Map<String, dynamic>;
      return app.User.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheUser(app.User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
