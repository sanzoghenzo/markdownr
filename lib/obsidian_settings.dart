import 'package:flutter/material.dart';

class ObsidianSettings {
  String vaultName;
  String filepath;
  String mode;
  bool daily;
  bool clipboard;
  String heading;

  ObsidianSettings({
    required this.vaultName,
    required this.filepath,
    required this.mode,
    required this.daily,
    required this.clipboard,
    required this.heading,
  });
}

String encodeForObsidian(String input) {
  return Uri.encodeComponent(Uri.encodeComponent(input));
}

class ObsidianSettingsPage extends StatefulWidget {
  final ObsidianSettings settings;
  final Function(ObsidianSettings) onSave;

  ObsidianSettingsPage({
    required this.settings,
    required this.onSave,
  });

  @override
  _ObsidianSettingsPageState createState() => _ObsidianSettingsPageState();
}

class _ObsidianSettingsPageState extends State<ObsidianSettingsPage> {
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
        title: Text('Obsidian Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              widget.onSave(currentSettings);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          DropdownButton<String>(
            value: currentSettings.mode,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  currentSettings.mode = newValue;
                });
              }
            },
            items: <String>['write', 'overwrite', 'append', 'prepend', 'new']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SwitchListTile(
            title: Text('Use Daily Note'),
            value: currentSettings.daily,
            onChanged: (newValue) {
              setState(() {
                currentSettings.daily = newValue;
              });
            },
          ),
          SwitchListTile(
            title: Text('Use Clipboard Content'),
            value: currentSettings.clipboard,
            onChanged: (newValue) {
              setState(() {
                currentSettings.clipboard = newValue;
              });
            },
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Heading'),
            onChanged: (value) {
              currentSettings.heading = value;
            },
            controller: TextEditingController(text: currentSettings.heading),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Filepath'),
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
