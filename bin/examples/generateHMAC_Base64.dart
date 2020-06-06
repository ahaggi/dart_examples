import 'dart:convert';
import 'package:crypto/crypto.dart';

main(List<String> arguments) async {
  generateToken();
}

void generateToken() {
  var authKey = "Mb37D1v9u3Nh9Yk2"; // AUTH. KEY for digit-eyes.com API
  var pcCode = "7038010007231"; // A product EAN code/ barcode
  var expectedSignature =
      "uXvNDt9bTd3JodO8cLlY7UWFAmM="; // expected signature ==

  var key = utf8.encode(authKey);
  var bytes = utf8.encode(pcCode);

  var hmacSha1 = new Hmac(sha1, key); // HMAC-SHA1
  var digest = hmacSha1.convert(bytes);

  var digestedByte = digest.bytes;
  var digestedBase64 = base64.encode(digest.bytes);
  // var digestedHex = digest.toString();
  // print("HMAC digest hex string: $digestedHex");

  print("HMAC digest as bytes: $digestedByte");

  print("HMAC digest as base64 string: $digestedBase64");
  print(
      "expectedSignature == digestedBase64: ${expectedSignature == digestedBase64}");
}
