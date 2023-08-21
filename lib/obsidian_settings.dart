import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ObsidianSettings {
  String vaultName;
  String filepath;
  String mode;
  bool daily;
  String? heading;  // Made heading optional

  ObsidianSettings({
    required this.vaultName,
    required this.filepath,
    required this.mode,
    required this.daily,
    this.heading,
  });

  // Add methods to save and load settings using SharedPreferences
  save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('vaultName', vaultName);
    prefs.setString('filepath', filepath);
    prefs.setString('mode', mode);
    prefs.setBool('daily', daily);
    prefs.setString('heading', heading ?? '');
  }

  static Future<ObsidianSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ObsidianSettings(
      vaultName: prefs.getString('vaultName') ?? '',
      filepath: prefs.getString('filepath') ?? 'Clipped From Markdownr',
      mode: prefs.getString('mode') ?? 'new',
      daily: prefs.getBool('daily') ?? false,
      heading: prefs.getString('heading') ?? "",
    );
  }
}

String encodeForObsidian(String input) {
  return Uri.encodeFull(input);
}

class ObsidianSettingsPage extends StatefulWidget {
  final ObsidianSettings settings;
  final Function(ObsidianSettings) onSave;

  const ObsidianSettingsPage({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  ObsidianSettingsPageState createState() => ObsidianSettingsPageState();
}

class ObsidianSettingsPageState extends State<ObsidianSettingsPage> {
  late ObsidianSettings currentSettings;

  @override
  void initState() {
    super.initState();
    currentSettings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obsidian Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              currentSettings.save();
              widget.onSave(currentSettings);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Vault Name'),
            onChanged: (value) {
              currentSettings.vaultName = value;
            },
            controller: TextEditingController(text: currentSettings.vaultName),
          ),
          DropdownButton<String>(
            value: currentSettings.mode,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  currentSettings.mode = newValue;
                });
              }
            },
            items: <String>['new', 'write', 'overwrite', 'append', 'prepend']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SwitchListTile(
            title: const Text('Use Daily Note'),
            value: currentSettings.daily,
            onChanged: (newValue) {
              setState(() {
                currentSettings.daily = newValue;
              });
            },
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Heading (Optional)'),
            onChanged: (value) {
              currentSettings.heading = value;
            },
            controller: TextEditingController(text: currentSettings.heading),
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Filepath'),
            onChanged: (value) {
              currentSettings.filepath = value;
            },
            controller: TextEditingController(text: currentSettings.filepath),
          ),
        ],
      ),
    );
  }
}
