import 'package:flutter/services.dart';

class ReadabilityOutput {
  const ReadabilityOutput({
    required this.content,
    required this.title,
    required this.author,
    required this.excerpt,
  });

  final String content;
  final String title;
  final String author;
  final String excerpt;

  factory ReadabilityOutput.fromResult(Map<Object?, Object?> result) {
    return ReadabilityOutput(
      content: result["html"] as String,
      title: result["title"] as String,
      author: result["author"] as String,
      excerpt: result["excerpt"] as String,
    );
  }
}

abstract class ReadabilityService {
  Future<ReadabilityOutput> makeReadable(String html, String url);
}

class DefaultReadabilityService implements ReadabilityService {
  @override
  Future<ReadabilityOutput> makeReadable(String html, String url) async {
    const platform = MethodChannel("com.sanzoghenzo/readability");
    var readableResults =
        await platform.invokeMethod("makeReadable", {"html": html, "url": url});
    if (readableResults == null) {
      throw AssertionError("Readability couldn't parse the HTML");
    }
    return ReadabilityOutput.fromResult(readableResults);
  }
}
