import 'package:flutter/material.dart';

import 'release_version.dart';

void main() => runApp(const SampleApp());

/// Type a pubspec.yaml version and see how Flutter splits it into a name and a build number.
class SampleApp extends StatefulWidget {
  const SampleApp({super.key});

  @override
  State<SampleApp> createState() => _SampleAppState();
}

class _SampleAppState extends State<SampleApp> {
  String _text = '1.4.0+27';

  @override
  Widget build(BuildContext context) {
    final version = ReleaseVersion.tryParse(_text);
    return MaterialApp(
      title: 'Flutter sample',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter sample')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const Key('input'),
                initialValue: _text,
                decoration: const InputDecoration(labelText: 'version: in pubspec.yaml'),
                onChanged: (value) => setState(() => _text = value),
              ),
              const SizedBox(height: 16),
              Text(
                version?.label ?? 'Not a Flutter version',
                key: const Key('result'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
