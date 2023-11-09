import 'package:html2md/html2md.dart' as html2md;
import 'package:intl/intl.dart';
import 'package:markdownr/notifications.dart';
import 'package:markdownr/readability.dart';
import 'package:markdownr/httpclient.dart';

class MarkdownArticle {
  const MarkdownArticle({
    required this.url,
    required this.content,
    required this.title,
    required this.author,
    required this.excerpt,
    required this.creationDate,
  });

  final String url;
  final String content;
  final String title;
  final String author;
  final String excerpt;
  final String creationDate;

  String get frontMatter =>
      "---\ncreated: $creationDate\nsource: $url\nauthor: $author\n---\n\n";

  String get sourceLinkSection => "Clipped from: $url\n\n";

  String get excerptSection => "## Excerpt\n\n> $excerpt\n\n";
}

class Url2MdConverter {
  Url2MdConverter({
    required HttpClient httpClient,
    required NotificationService notificationService,
    required ReadabilityService readabilityService,
  })  : _httpClient = httpClient,
        _notificationService = notificationService,
        _readabilityService = readabilityService;

  final HttpClient _httpClient;
  final NotificationService _notificationService;
  final ReadabilityService _readabilityService;

  Future<MarkdownArticle> convertPage({required String url}) async {
    var dateFmt = DateFormat("yyyy-MM-ddThh:mm:ss");
    var formattedDate = dateFmt.format(DateTime.now());
    try {
      var html = await _httpClient.getPage(url);
      var readableResults = await _readabilityService.makeReadable(html, url);
      var markdown = html2md.convert(readableResults.content, styleOptions: {
        "headingStyle": "atx",
        "hr": "---",
        "bulletListMarker": "-",
        "codeBlockStyle": "fenced",
      });
      var title = readableResults.title;
      var author = readableResults.author;
      var excerpt = readableResults.excerpt;
      return MarkdownArticle(
          url: url,
          content: markdown,
          title: title,
          author: author,
          excerpt: excerpt,
          creationDate: formattedDate);
    } catch (e) {
      _notificationService.showToast("$e");
      return MarkdownArticle(
          url: url,
          content: "",
          title: "",
          author: "",
          excerpt: "",
          creationDate: formattedDate);
    }
  }
}
