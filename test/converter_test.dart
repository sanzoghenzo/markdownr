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

    test('convert should return valid markdown', () async {
      const url = 'https://example.com';
      const content = '<h2>Test Header</h2><p>Test paragraph</p>';
      const html =
          '<html><head><title>Test Title</title></head><body>$content</body></html>';
      when(mockHttpClient.getPage(url)).thenAnswer((_) async => html);
      when(mockReadabilityService.makeReadable(html, url)).thenAnswer(
          (_) async => const ReadabilityOutput(
              content: '<div>$content</div>',
              title: "Test Title",
              author: "Myself",
              excerpt: "A really good article"));
      final markdown = await url2mdConverter.convertPage(url: url);
      expect(markdown.url, url);
      expect(markdown.content, "## Test Header\n\nTest paragraph");
      expect(markdown.title, "Test Title");
      expect(markdown.author, "Myself");
      expect(markdown.excerpt, "A really good article");
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
  });
}
