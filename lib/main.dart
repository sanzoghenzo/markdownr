import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html2md/html2md.dart' as html2md;
import 'package:share_plus/share_plus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  Future<bool> getIncludeSourceLink() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("includeSourceLink") ?? true;
  }

  setIncludeSourceLink(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("includeSourceLink", value);
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

  void fromIntent(String value) async {
    _controller.text = value;
    var md = await url2md(value);
    setState(() {
      url = value;
      markdown = md;
    });
    Share.share(markdown);
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

    getIncludeSourceLink().then((value) => includeSourceLink = value);
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
                  setState(() {includeSourceLink = !includeSourceLink;});
                  setIncludeSourceLink(includeSourceLink);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                child: CheckedPopupMenuItem(
                  checked: includeSourceLink,
                  value: 1,
                  child: const Text("Include URL"),
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
            ],
          ),
        ],
      ),
    );
  }

  Future<String> url2md(String url) async {
    try {
      String html = await http.read(Uri.parse(url));
      Map<Object?, Object?>? readableResults = await platform
          .invokeMethod("makeReadable", {"html": html, "url": url});
      var title = readableResults!["title"] as String;
      var readable = readableResults["html"] as String;
      String markdown = html2md.convert(readable, styleOptions: {
        "headingStyle": "atx",
        "hr": "---",
        "bulletListMarker": "-",
        "codeBlockStyle": "fenced",
      });
      var link = await getIncludeSourceLink() ? "\nClipped from: $url\n" : "";
      return "# $title\n$link\n$markdown";
    } catch (e) {
      Fluttertoast.showToast(msg: "$e");
      return "";
    }
  }
}
