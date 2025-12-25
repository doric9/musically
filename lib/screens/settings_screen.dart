import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Audio Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Audio Input Device'),
            subtitle: const Text('Default Microphone'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement audio device selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Audio device selection coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: const Text('Audio Quality'),
            subtitle: const Text('High (44.1 kHz, 16-bit)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement audio quality settings
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Display Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome),
            title: const Text('Auto-scroll'),
            subtitle: const Text('Automatically scroll as you play'),
            value: true,
            onChanged: (bool value) {
              // TODO: Save preference
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.zoom_in),
            title: const Text('Auto-zoom'),
            subtitle: const Text('Zoom to current measure'),
            value: true,
            onChanged: (bool value) {
              // TODO: Save preference
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'AI Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('Gemini API Key'),
            subtitle: const Text('Not configured'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement API key configuration
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('API key configuration coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Detection Sensitivity'),
            subtitle: const Text('Medium'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement sensitivity settings
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(context: context);
            },
          ),
        ],
      ),
    );
  }
}
