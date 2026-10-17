import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../utils/database_helper.dart';
import '../utils/validation.dart';

class AuthController {
  final _helper = DatabaseHelper.instance;

  static const int _iterations = 210000;

  Future<String> _hashPassword(
    String password,
    List<int> salt,
    int iterations,
  ) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );

    final key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    return base64Encode(await key.extractBytes());
  }

  Future<void> register(String email, String password) async {
    if (emailError(email) != null) {
      throw ArgumentError('Email không hợp lệ.');
    }

    if (password.length < 6 || password.trim().isEmpty) {
      throw ArgumentError('Mật khẩu cần ít nhất 6 ký tự.');
    }

    final random = Random.secure();

    final salt = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    final hash = await _hashPassword(
      password,
      salt,
      _iterations,
    );

    final db = await _helper.database;

    await db.insert('users', {
      'email': email.trim().toLowerCase(),
      'passwordHash': hash,
      'salt': base64Encode(salt),
      'iterations': _iterations,
    });
  }

  Future<bool> login(String email, String password) async {
    final db = await _helper.database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (result.isEmpty) return false;

    final user = result.single;

    final enteredHash = await _hashPassword(
      password,
      base64Decode(user['salt'] as String),
      user['iterations'] as int,
    );

    final enteredBytes = base64Decode(enteredHash);
    final savedBytes = base64Decode(user['passwordHash'] as String);

    if (enteredBytes.length != savedBytes.length) return false;

    var difference = 0;

    for (var i = 0; i < enteredBytes.length; i++) {
      difference |= enteredBytes[i] ^ savedBytes[i];
    }

    return difference == 0;
  }
}