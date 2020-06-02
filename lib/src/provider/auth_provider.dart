import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logindemo/src/http_exception.dart';
import 'package:logindemo/src/resourch/socket_client.dart';

import 'package:logindemo/src/style/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  List<Account> _account = [];
  String _token;
SimpleWebSocket _socket;
  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_token != null) {
      return _token;
    }
    return null;
  }

  List<Account> get account => _account;

  Map<String, String> requestHeaders = {
    'Accept': 'application/json',
    'Content-type': 'application/json'
  };

  void sha512enCode(
      String token, String password, String passwordsha, String saltKey)  async{
    List<int> key = utf8.encode(saltKey);
    List<int> bytes = utf8.encode(password);
    var hmacSha256 = new Hmac(sha512, key); // HMAC-SHA256
    var digest = hmacSha256.convert(bytes);
    print(digest);
    print('passs so sanh :$passwordsha');
    if (digest.toString() == passwordsha) {
      List<Account> _loaderAcount = [];
      _loaderAcount.add(Account(webtoken: token));
      _account = _loaderAcount;
      _token = token;
      _socket=SimpleWebSocket("https://uoi.bachasoftware.com/socket-chat/");
      await _socket.connect();
      notifyListeners();
    } else {
      _token == null;
      _account.clear();
      ToastShare().getToast("Mật Khẩu Không chính xác");
      notifyListeners();
    }
  }

// ----------------------login to uoi---------------------------
  Future<void> _authenticate(String Email, String Password) async {
    final url = "https://uoi.bachasoftware.com/api/login";
    try {
      final response = await http.post(url,
          headers: requestHeaders,
          body: json.encode({
            'email': Email,
          }));
      final responseData = json.decode(response.body);
      if (responseData == null) {
        return;
      }
      sha512enCode(responseData['webToken'], Password, responseData['password'],
          responseData['saltKey']);
      if (responseData['error'] != null) {
        throw HttpException(responseData['message']);
      }
      if (responseData['message'] == 'not verified') {
        ToastShare().getToast("Email của bạn chưa được đăng kí");
      }
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonEncode({
        'id': responseData['id'],
        'webToken': responseData['webToken'],
        'password': responseData['password'],
        'pasinput': Password,
        'saltKey': responseData['saltKey']
      });
      prefs.setString('userData', userData);
      print(userData);
    } catch (error) {
      print(error);
    }
  }

  //-----------------------End Login------------------------------------
  Future<bool> autologin() async {
    final perfs = await SharedPreferences.getInstance();
    if (!perfs.containsKey('userData')) {
      return false;
    }
    final extraxUserData =
        json.decode(perfs.get('userData')) as Map<String, Object>;
    final webToken = extraxUserData['webToken'];
    if (webToken == null) {
      return false;
    }
    final password = extraxUserData['password'];
    final pasinput = extraxUserData['pasinput'];
    final saltKey = extraxUserData['saltKey'];
    sha512enCode(webToken, pasinput, password, saltKey);
    notifyListeners();
    return true;
  }

  //---------------------Signup------------------------------------------

  Future<void> singup(String email, String password) async {
    return _authenticate(email, password);
  }
}

class Account with ChangeNotifier {
  final String webtoken;

  Account({@required this.webtoken});
}