import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String raw, {String salt = 'goodmusic_v1'}) {
  final bytes = utf8.encode('$salt::$raw');
  return sha256.convert(bytes).toString();
}
