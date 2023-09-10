import 'package:html2md/html2md.dart' as html2md;
import 'package:intl/intl.dart';
import 'package:markdownr/notifications.dart';
import 'package:markdownr/readability.dart';
import 'package:markdownr/settings.dart';
import 'package:markdownr/httpclient.dart';

class Url2MdConverter {
  Url2MdConverter({
    required HttpClient httpClient,
    required SettingsRepository settingsRepository,
    required NotificationService notificationService,
    required ReadabilityService readabilityService,
  })  : _httpClient = httpClient,
        _settingsRepository = settingsRepository,
        _notificationService = notificationService,
        _readabilityService = readabilityService;

  final HttpClient _httpClient;
  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;
  final ReadabilityService _readabilityService;

  Future<String> convert({required String url}) async {
    try {
      var html = await _httpClient.getPage(url);
      var readableResults = await _readabilityService.makeReadable(html, url);
      var markdown =
          _settingsRepository.getBool("includeBody", defaultValue: true)
              ? html2md.convert(readableResults.content, styleOptions: {
                  "headingStyle": "atx",
                  "hr": "---",
                  "bulletListMarker": "-",
                  "codeBlockStyle": "fenced",
                })
              : "";
      var preamble = await _buildPreamble(readableResults, url);
      return "$preamble$markdown";
    } catch (e) {
      _notificationService.showToast("$e");
      return "";
    }
  }

  Future<String> _buildPreamble(
      ReadabilityOutput readableResults, String url) async {
    var title = readableResults.title;
    var author = readableResults.author;
    var excerpt = readableResults.excerpt;
    var dateFmt = DateFormat("yyyy-MM-ddThh:mm:ss");
    var formattedDate = dateFmt.format(DateTime.now());
    var frontMatter = _settingsRepository.getBool("includeFrontMatter")
        ? "---\ncreated: $formattedDate\nsource: $url\nauthor: $author\n---\n\n"
        : "";
    var link = _settingsRepository.getBool("includeSourceLink")
        ? "Clipped from: $url\n\n"
        : "";
    var excerptString = _settingsRepository.getBool("includeExcerpt")
        ? "## Excerpt\n\n> $excerpt\n\n"
        : "";
    return "$frontMatter# $title\n\n$link$excerptString";
  }
}
