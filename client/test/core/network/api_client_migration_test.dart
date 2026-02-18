import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature layer does not declare http.Client directly', () {
    final libDir = Directory('lib');
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('core/network/api_client.dart'));

    final offenders = <String>[];

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      if (content.contains('http.Client')) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty, reason: 'These files still use http.Client: $offenders');
  });
}
