import 'dart:async';
import 'dart:convert';

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html2md/html2md.dart' as html2md;
import 'package:share_plus/share_plus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
      home: const MyHomePage(title: 'Markdownr'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel("com.sanzoghenzo/readability");
  final TextEditingController _controller = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;
  String url = "";
  String markdown = "";
  bool includeSourceLink = true;
  bool includeFrontMatter = true;
  bool includeExcerpt = true;
  bool includeBody = true;

  Future<bool> getSettings(String settingName,
      {bool defaultValue = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(settingName) ?? defaultValue;
  }

  setSettings(String name, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(name, value);
  }

  void _convert() async {
    var md = await url2md(url);
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

  void fromIntent(String value) async {
    _controller.text = value;
    var md = await url2md(value);
    setState(() {
      url = value;
      markdown = md;
    });
    if (markdown.isNotEmpty) {
      Share.share(markdown);
    }
  }

  @override
  void initState() {
    super.initState();
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen(fromIntent, onError: (err) {
      Fluttertoast.showToast(msg: "Error receiving the intent: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) async {
      if (value != null && value.isNotEmpty) {
        fromIntent(value);
      }
    });

    getSettings("includeSourceLink").then((value) => includeSourceLink = value);
    getSettings("includeFrontMatter")
        .then((value) => includeFrontMatter = value);
    getSettings("includeExcerpt").then((value) => includeExcerpt = value);
    getSettings("includeBody", defaultValue: true).then((value) => includeBody = value);
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<int>(
            onSelected: (int result) {
              switch (result) {
                case 1:
                  setState(() {
                    includeFrontMatter = !includeFrontMatter;
                  });
                  setSettings("includeFrontMatter", includeFrontMatter);
                  break;
                case 2:
                  setState(() {
                    includeSourceLink = !includeSourceLink;
                  });
                  setSettings("includeSourceLink", includeSourceLink);
                  break;
                case 3:
                  setState(() {
                    includeExcerpt = !includeExcerpt;
                  });
                  setSettings("includeExcerpt", includeExcerpt);
                  break;
                case 4:
                  setState(() {
                    includeBody = !includeBody;
                  });
                  setSettings("includeBody", includeBody);
                  break;
              }
            },
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

  Future<String> url2md(String url) async {
    try {
      String html = await _getHtmlText(url);
      Map<Object?, Object?>? readableResults = await platform
          .invokeMethod("makeReadable", {"html": html, "url": url});
      var title = readableResults!["title"] as String;
      var readable = readableResults["html"] as String;
      var author = readableResults["author"] as String;
      var excerpt = readableResults["excerpt"] as String;
      var markdown = await getSettings("includeBody") ?
        html2md.convert(readable, styleOptions: {
          "headingStyle": "atx",
          "hr": "---",
          "bulletListMarker": "-",
          "codeBlockStyle": "fenced",
        })
        : "";
      var dateFmt = DateFormat("yyyy-MM-ddThh:mm:ss");
      var formattedDate = dateFmt.format(DateTime.now());
      var frontMatter = await getSettings("includeFrontMatter")
          ? "---\ncreated: $formattedDate\nsource: $url\nauthor: $author\n---\n\n"
          : "";
      var link = await getSettings("includeSourceLink")
          ? "Clipped from: $url\n\n"
          : "";
      var excerptString = await getSettings("includeExcerpt")
          ? "## Excerpt\n\n> $excerpt\n\n"
          : "";
      return "$frontMatter# $title\n\n$link$excerptString$markdown";
    } catch (e) {
      Fluttertoast.showToast(msg: "$e");
      return "";
    }
  }

  Future<String> _getHtmlText(String url) async {
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
