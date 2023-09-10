import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:markdownr/converter.dart';
import 'package:markdownr/httpclient.dart';
import 'package:markdownr/notifications.dart';
import 'package:markdownr/readability.dart';
import 'package:markdownr/settings.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdownr',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'Markdownr'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;
  String url = "";
  String markdown = "";
  bool includeSourceLink = false;
  bool includeFrontMatter = false;
  bool includeExcerpt = false;
  bool includeBody = true;
  late final Url2MdConverter _url2MdConverter;
  late final SettingsRepository _settingsRepository;

  _HomePageState();

  @override
  void initState() {
    super.initState();
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen(fromIntent, onError: (err) {
      Fluttertoast.showToast(msg: "Error receiving the intent: $err");
    });

    ReceiveSharingIntent.getInitialText().then((String? value) async {
      if (value != null && value.isNotEmpty) {
        fromIntent(value);
      }
    });

    repoFactory().then((repo){
      _settingsRepository = repo;
      _url2MdConverter = Url2MdConverter(
          httpClient: const DefaultHttpClient(),
          settingsRepository: _settingsRepository,
          notificationService: const DefaultNotificationService(),
          readabilityService: DefaultReadabilityService()
      );
      includeFrontMatter = _settingsRepository.getBool("includeFrontMatter");
      includeSourceLink = _settingsRepository.getBool("includeSourceLink");
      includeExcerpt = _settingsRepository.getBool("includeExcerpt");
      includeBody =
        _settingsRepository.getBool("includeBody", defaultValue: true);
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void fromIntent(String value) async {
    _controller.text = value;
    var md = await _url2MdConverter.convert(url: value);
    setState(() {
      url = value;
      markdown = md;
    });
    if (markdown.isNotEmpty) {
      Share.share(markdown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              )
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical, //.horizontal
                child: Text(
                  markdown,
                  softWrap: true,
                ),
              ),
            ),
          ),
          Row(
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
          ),
        ],
      ),
    );
  }

  void _handleSettings(int result) {
    switch (result) {
      case 1:
        setState(() {
          includeFrontMatter = !includeFrontMatter;
        });
        _setPreference("includeFrontMatter", includeFrontMatter);
        break;
      case 2:
        setState(() {
          includeSourceLink = !includeSourceLink;
        });
        _setPreference("includeSourceLink", includeSourceLink);
        break;
      case 3:
        setState(() {
          includeExcerpt = !includeExcerpt;
        });
        _setPreference("includeExcerpt", includeExcerpt);
        break;
      case 4:
        setState(() {
          includeBody = !includeBody;
        });
        _setPreference("includeBody", includeBody);
        break;
    }
  }

  void _setPreference(String settingName, bool value) {
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(settingName, value));
  }

  void _convert() async {
    var md = await _url2MdConverter.convert(url: url);
    setState(() {
      markdown = md;
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
