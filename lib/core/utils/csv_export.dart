import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

String _csvCell(dynamic value) {
  final text = (value ?? '').toString();
  if (text.contains(',') || text.contains('"') || text.contains('\n')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

String buildCsv(List<String> headers, List<List<dynamic>> rows) {
  final buffer = StringBuffer();
  buffer.writeln(headers.map(_csvCell).join(','));
  for (final row in rows) {
    buffer.writeln(row.map(_csvCell).join(','));
  }
  return buffer.toString();
}

/// Writes a CSV to a temp file and opens the OS share/open sheet for it —
/// the simplest export path available without a dedicated share package.
Future<void> exportCsv(BuildContext context, String filename, List<String> headers, List<List<dynamic>> rows) async {
  try {
    final csv = buildCsv(headers, rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv, flush: true);
    await OpenFile.open(file.path);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not export CSV: $e')));
    }
  }
}
