import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdownr/converter.dart';
import 'package:markdownr/httpclient.dart';
import 'package:markdownr/notifications.dart';
import 'package:markdownr/readability.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<HttpClient>(),
  MockSpec<NotificationService>(),
  MockSpec<ReadabilityService>(),
])
import 'converter_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Url2MdConverter', () {
    late MockHttpClient mockHttpClient;
    late MockNotificationService mockNotificationService;
    late Url2MdConverter url2mdConverter;
    late ReadabilityService mockReadabilityService;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockNotificationService = MockNotificationService();
      mockReadabilityService = MockReadabilityService();
      url2mdConverter = Url2MdConverter(
        httpClient: mockHttpClient,
        notificationService: mockNotificationService,
        readabilityService: mockReadabilityService,
      );
    });

    test('convert should handle exceptions', () async {
      const url = 'https://example.com';
      when(mockHttpClient.getPage(url)).thenThrow(Exception());
      final markdown = await url2mdConverter.convertPage(url: url);
      expect(markdown.url, url);
      expect(markdown.content, "");
      expect(markdown.title, "");
      expect(markdown.author, "");
      expect(markdown.excerpt, "");
    });

    void fileBasedTestCase(fileName) {
      test('Convert case $fileName', () async {
        const url = "https://www.example.com";
        final file = File('test/resources/$fileName.html');
        var content = await file.readAsString();
        final html =
            '<html><head><title>Title</title></head><body>$content</body></html>';
        when(mockHttpClient.getPage(url)).thenAnswer((_) async => html);
        when(mockReadabilityService.makeReadable(html, url)).thenAnswer(
            (_) async => ReadabilityOutput(
                content: content,
                title: "Title",
                author: "Author",
                excerpt: "A really good article"));
        final markdown = await url2mdConverter.convertPage(url: url);
        final mdFile = File('test/resources/$fileName.md');
        var mdContent = await mdFile.readAsString();
        expect(markdown.content, mdContent);
      });
    }

    fileBasedTestCase('simple');
    fileBasedTestCase('jekyll-code-block');
    fileBasedTestCase('jekyll-code-block-no-language');
  });
}
