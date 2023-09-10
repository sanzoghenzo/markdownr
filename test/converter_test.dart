import 'package:flutter_test/flutter_test.dart';
import 'package:markdownr/converter.dart';
import 'package:markdownr/httpclient.dart';
import 'package:markdownr/notifications.dart';
import 'package:markdownr/readability.dart';
import 'package:markdownr/settings.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<HttpClient>(),
  MockSpec<SettingsRepository>(),
  MockSpec<NotificationService>(),
  MockSpec<ReadabilityService>(),
])
import 'converter_test.mocks.dart';

void main() {
  group('Url2MdConverter', () {
    late MockHttpClient mockHttpClient;
    late MockSettingsRepository mockSettingsRepository;
    late MockNotificationService mockNotificationService;
    late Url2MdConverter url2mdConverter;
    late ReadabilityService mockReadabilityService;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockSettingsRepository = MockSettingsRepository();
      mockNotificationService = MockNotificationService();
      mockReadabilityService = MockReadabilityService();
      url2mdConverter = Url2MdConverter(
        httpClient: mockHttpClient,
        settingsRepository: mockSettingsRepository,
        notificationService: mockNotificationService,
        readabilityService: mockReadabilityService,
      );
    });

    test('convert should return valid markdown', () async {
      const url = 'https://example.com';
      const content = '<h2>Test Header</h2><p>Test paragraph</p>';
      const html =
          '<html><head><title>Test Title</title></head><body>$content</body></html>';
      const expectedMarkdown =
          '# Test Title\n\n## Test Header\n\nTest paragraph';
      when(mockHttpClient.getPage(url)).thenAnswer((_) async => html);
      when(mockSettingsRepository.getBool('includeFrontMatter'))
          .thenAnswer((_) => false);
      when(mockSettingsRepository.getBool('includeSourceLink'))
          .thenAnswer((_) => false);
      when(mockSettingsRepository.getBool('includeExcerpt'))
          .thenAnswer((_) => false);
      when(mockSettingsRepository.getBool('includeBody', defaultValue: true))
          .thenAnswer((_) => true);
      when(mockReadabilityService.makeReadable(html, url)).thenAnswer(
          (_) async => const ReadabilityOutput(
              content: '<div>$content</div>',
              title: "Test Title",
              author: "",
              excerpt: ""));
      final markdown = await url2mdConverter.convert(url: url);
      expect(markdown, expectedMarkdown);
    });

    test('convert should handle exceptions', () async {
      const url = 'https://example.com';
      when(mockHttpClient.getPage(url)).thenThrow(Exception());
      final markdown = await url2mdConverter.convert(url: url);
      expect(markdown, '');
    });
  });
}
