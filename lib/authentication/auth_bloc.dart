import 'dart:convert';
import 'dart:io';

import 'package:australti_ecommerce_app/global/enviroments.dart';
import 'package:australti_ecommerce_app/models/auth_response.dart';
import 'package:australti_ecommerce_app/models/profile.dart';
import 'package:australti_ecommerce_app/models/store.dart';
import 'package:australti_ecommerce_app/models/user.dart';
import 'package:australti_ecommerce_app/preferences/user_preferences.dart';
import 'package:australti_ecommerce_app/widgets/show_alert_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mime_type/mime_type.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http_parser/http_parser.dart';

enum AuthState { isClient, isStore }

class AuthenticationBLoC with ChangeNotifier {
  final prefs = new AuthUserPreferences();
  bool _imageProfileChanges = false;
  set imageProfileChange(bool value) {
    this._imageProfileChanges = value;
    notifyListeners();
  }

  bool get isImageProfileChange => this._imageProfileChanges;

  AuthState authState = AuthState.isStore;
  static String redirectUri =
      '${Environment.apiUrl}/api/apple/callbacks/sign_in_with_apple';
  static String clientId = 'com.kiozer';
  static GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
    ],
  );
  final _storage = new FlutterSecureStorage();
  ValueNotifier<bool> notifierBottomBarVisible = ValueNotifier(true);

  bool isAuthenticated = false;

  Profile _profileAuth;

  Store _storeAuth;

  String _redirect;

  appleSignIn(BuildContext context) async {
    bool isIos = UniversalPlatform.isIOS;
    //bool isWeb = UniversalPlatform.isWeb;

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
              clientId: clientId, redirectUri: Uri.parse(redirectUri)));

      final useBundleId = isIos ? true : false;

      showModalLoading(context);

      final res = await this.siginWithApple(
          credential.authorizationCode,
          credential.email,
          credential.givenName,
          useBundleId,
          credential.state);

      print(res);

      Navigator.pop(context);

      return res;
    } catch (e) {
      print(e);
    }
  }

  void changeToStore() {
    authState = AuthState.isStore;
    notifyListeners();
  }

  void changeToClient() {
    authState = AuthState.isStore;
    notifyListeners();
  }

  ValueNotifier<bool> get bottomVisible => this.notifierBottomBarVisible;

  set bottomVisible(ValueNotifier<bool> valor) {
    this.notifierBottomBarVisible = valor;
    notifyListeners();
  }

  Profile get profile => this._profileAuth;

  set profile(Profile valor) {
    this._profileAuth = valor;
    notifyListeners();
  }

  Store get storeAuth => this._storeAuth;

  set storeAuth(Store valor) {
    this._storeAuth = valor;
    notifyListeners();
  }

  String get redirect => this._redirect;

  set redirect(String valor) {
    this._redirect = valor;
    //notifyListeners();
  }

  Future _guardarToken(String token) async {
    return await _storage.write(key: 'token', value: token);
  }

  Future logout() async {
    await _storage.delete(key: 'token');

    //signOut();
  }

  static Future signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<String> getToken() async {
    final _storage = new FlutterSecureStorage();
    final token = await _storage.read(key: 'token');
    return token;
  }

  Future editProfile(String uid, String username, String about, String name,
      String email, String password, String imageAvatar) async {
    // this.authenticated = true;

    final urlFinal = ('${Environment.apiUrl}/api/store/edit');

    final data = {
      'uid': uid,
      'username': username,
      'name': name,
      'about': about,
      'email': email,
      'password': password,
      'imageAvatar': imageAvatar
    };

    String token = '';
    (UniversalPlatform.isWeb)
        ? token = prefs.token
        : token = await this._storage.read(key: 'token');

    final resp = await http.post(Uri.parse(urlFinal),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json', 'x-token': token});

    if (resp.statusCode == 200) {
      final loginResponse = loginResponseFromJson(resp.body);

      storeAuth = loginResponse.store;

      return true;
    } else {
      final respBody = jsonDecode(resp.body);
      return respBody['msg'];
    }
  }

  Future siginWithApple(String code, String email, String firstName,
      bool useBundleId, String state) async {
    final urlFinal = '${Environment.apiUrl}/api/apple/sign_in_with_apple';

    final data = {
      'code': code,
      'email': email,
      'firstName': firstName,
      'useBundleId': useBundleId,
      if (state != null) 'state': state
    };
    final resp = await http.post(Uri.parse(urlFinal),
        body: jsonEncode(data), headers: {'Content-Type': 'application/json'});

    if (resp.statusCode == 200) {
      final loginResponse = loginResponseFromJson(resp.body);

      storeAuth = loginResponse.store;

      _guardarToken(loginResponse.token);

      // await getProfileByUserId(this.profile.user.uid);

      return true;
    } else {
      return false;
    }

    // await getProfileByUserId(this.profile.user.uid);
  }

  Future<String> uploadImageProfile(
      String fileName, String fileType, File image) async {
    final url = ('${Environment.apiUrl}/api/aws/upload/image-avatar');

    final mimeType = mime(image.path).split('/'); //image/jpeg

    String token = '';
    (UniversalPlatform.isWeb)
        ? token = prefs.token
        : token = await this._storage.read(key: 'token');

    Map<String, String> headers = {
      "Content-Type": "image/mimeType",
      "x-token": token,
    };

    final imageUploadRequest = http.MultipartRequest('POST', Uri.parse(url));

    final file = await http.MultipartFile.fromPath('file', image.path,
        contentType: MediaType(mimeType[0], mimeType[1]));

    imageUploadRequest.files.add(file);

    imageUploadRequest.headers.addAll(headers);

    final streamResponse = await imageUploadRequest.send();
    final resp = await http.Response.fromStream(streamResponse);

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      print('Algo salio mal');

      return null;
    }

    final respBody = jsonDecode(resp.body);

    //final respData = imageResponseToJson(resp.body);

    final respUrl = respBody['url'];

    // storeAuth.imageAvatar = respUrl;

    return respUrl;
  }

  Future<bool> isLoggedIn() async {
    var urlFinal = ('${Environment.apiUrl}/api/login/renew');

    String token = '';
    (UniversalPlatform.isWeb)
        ? token = prefs.token
        : token = await this._storage.read(key: 'token');

    //this.logout();
    final resp = await http.get(Uri.parse(urlFinal),
        headers: {'Content-Type': 'application/json', 'x-token': token});
    if (resp.statusCode == 200) {
      final loginResponse = loginResponseFromJson(resp.body);

      storeAuth = loginResponse.store;

      return true;
    } else {
      storeAuth = Store(user: User(uid: '0'));
      (UniversalPlatform.isWeb) ? prefs.setToken = '' : this.logout();
      return false;
    }
  }
}
