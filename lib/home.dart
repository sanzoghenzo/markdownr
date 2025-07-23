import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:markdownr/converter.dart';
import 'package:markdownr/httpclient.dart';
import 'package:markdownr/notifications.dart';
import 'package:markdownr/readability.dart';
import 'package:markdownr/settings.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;
  String url = "";
  String markdown = "";
  String markdownPreview = "";
  bool includeSourceLink = false;
  bool includeFrontMatter = false;
  bool includeExcerpt = false;
  bool includeBody = true;
  bool showPreview = false;
  MarkdownArticle? article;
  late final Url2MdConverter? _url2MdConverter;
  late final SettingsRepository _settingsRepository;

  _HomePageState();

  @override
  void initState() {
    super.initState();
    // share intent received while running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(fromIntent, onError: (err) {
      Fluttertoast.showToast(msg: "Error receiving the intent: $err");
    });

    // share intent received while closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) async {
      var repo = await repoFactory();
      initStateInternal(repo);
      fromIntent(value);
      ReceiveSharingIntent.instance.reset();
    });

    repoFactory().then(initStateInternal);
  }

  void initStateInternal(SharedPreferencesSettingsRepository repo) {
    _settingsRepository = repo;
    _url2MdConverter = Url2MdConverter(
        httpClient: const DefaultHttpClient(),
        notificationService: const DefaultNotificationService(),
        readabilityService: DefaultReadabilityService());
    includeFrontMatter = _settingsRepository.getBool("includeFrontMatter");
    includeSourceLink = _settingsRepository.getBool("includeSourceLink");
    includeExcerpt = _settingsRepository.getBool("includeExcerpt");
    includeBody =
        _settingsRepository.getBool("includeBody", defaultValue: true);
    showPreview = _settingsRepository.getBool("showPreview");
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void fromIntent(List<SharedMediaFile> value) async {
    if (value.isEmpty) {
      return;
    }
    var urlValue = value.singleOrNull?.path;
    if (urlValue == null || urlValue.isEmpty) {
      return;
    }
    _controller.text = urlValue;
    if (_url2MdConverter == null) {
      var repo = await repoFactory();
      initStateInternal(repo);
    }
    setState(() {
      url = urlValue;
    });
    article = await _url2MdConverter?.convertPage(url: urlValue);
    _updateMarkdown();
    if (markdown.isNotEmpty) {
      Share.share(markdown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints.expand(),
        alignment: Alignment.center,
        child: Scaffold(
          appBar: _buildAppBar(),
          body: Column(
            children: <Widget>[
              _buildUrlInput(),
              _buildMarkdownView(),
              _buildButtonsRow(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.title),
      actions: [
        PopupMenuButton<int>(
          onSelected: _handleSettings,
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              child: CheckedPopupMenuItem(
                checked: includeFrontMatter,
                value: 1,
                child: const Text("Include front matter"),
              ),
            ),
            PopupMenuItem<int>(
              child: CheckedPopupMenuItem(
                checked: includeSourceLink,
                value: 2,
                child: const Text("Include URL in content"),
              ),
            ),
            PopupMenuItem<int>(
              child: CheckedPopupMenuItem(
                checked: includeExcerpt,
                value: 3,
                child: const Text("Include Excerpt"),
              ),
            ),
            PopupMenuItem<int>(
              child: CheckedPopupMenuItem(
                checked: includeBody,
                value: 4,
                child: const Text("Include Body"),
              ),
            ),
            PopupMenuItem<int>(
              child: CheckedPopupMenuItem(
                checked: showPreview,
                value: 5,
                child: const Text("Show Preview"),
              ),
            )
          ],
        ),
      ],
    );
  }

  Padding _buildUrlInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Enter a URL',
        ),
        onChanged: (value) {
          url = value;
        },
        controller: _controller,
      ),
    );
  }

  Expanded _buildMarkdownView() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical, //.horizontal
          child: showPreview
              ? MarkdownBody(data: markdownPreview)
              : SelectableText(markdown),
        ),
      ),
    );
  }

  Row _buildButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: _convert,
              child: const Text('CONVERT'),
            ),
          ],
        ),
        Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: markdown.isNotEmpty ? _share : null,
              child: const Text('SHARE'),
            ),
          ],
        ),
        Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: markdown.isNotEmpty ? _toClipboard : null,
              child: const Text('COPY'),
            ),
          ],
        ),
      ],
    );
  }

  void _handleSettings(int result) {
    setState(() {
      switch (result) {
        case 1:
          includeFrontMatter = _togglePreference("includeFrontMatter");
          break;
        case 2:
          includeSourceLink = _togglePreference("includeSourceLink");
          break;
        case 3:
          includeExcerpt = _togglePreference("includeExcerpt");
          break;
        case 4:
          includeBody = _togglePreference("includeBody");
          break;
        case 5:
          showPreview = _togglePreference("showPreview");
          break;
      }
    });
    _updateMarkdown();
  }

  bool _togglePreference(String settingName) {
    var newValue = !_settingsRepository.getBool(settingName);
    _settingsRepository.setBool(settingName, newValue);
    return newValue;
  }

  void _convert() async {
    article = await _url2MdConverter?.convertPage(url: url);
    _updateMarkdown();
  }

  void _updateMarkdown() {
    var title = article!.title;
    var body = includeBody ? article!.content : "";
    var frontMatter = includeFrontMatter ? article!.frontMatter : "";
    var link = includeSourceLink ? article!.sourceLinkSection : "";
    var excerpt = includeExcerpt ? article!.excerptSection : "";
    setState(() {
      markdown = "$frontMatter# $title\n\n$link$excerpt$body";
      markdownPreview = "# $title\n\n$link$excerpt$body";
    });
  }

  void _share() {
    Share.share(markdown);
  }

  void _toClipboard() {
    Clipboard.setData(ClipboardData(text: markdown)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to your clipboard!')));
    });
  }
}
