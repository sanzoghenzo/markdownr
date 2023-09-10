import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:charset_converter/charset_converter.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';

abstract class HttpClient {
  Future<String> getPage(String url);
}

class DefaultHttpClient implements HttpClient {
  const DefaultHttpClient();

  @override
  Future<String> getPage(String url) async {
    var response = await http.get(Uri.parse(url));
    var rawBytes = response.bodyBytes;
    try {
      return utf8.decode(rawBytes);
    } catch (_) {}
    try {
      return (await CharsetDetector.autoDecode(rawBytes)).string;
    } catch (_) {}
    if (response.headers.containsKey("content-type")) {
      String ct = response.headers["content-type"]!;
      if (ct.contains("charset")) {
        var charset = ct.split("charset=")[1];
        return await CharsetConverter.decode(charset, rawBytes);
      }
    }
    throw Exception("Could not get text from the specified URL");
  }
}
