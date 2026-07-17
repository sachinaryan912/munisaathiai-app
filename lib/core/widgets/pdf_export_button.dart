import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';

/// Downloads PDF bytes via [download], writes them to the device's temp
/// directory under [fileName], and hands off to the OS to open — the shared
/// "Export PDF" action reused by every AI report screen so the write/open
/// flow isn't duplicated per screen.
class PdfDownloadButton extends StatefulWidget {
  final String fileName;
  final Future<List<int>> Function() download;
  const PdfDownloadButton({super.key, required this.fileName, required this.download});

  @override
  State<PdfDownloadButton> createState() => _PdfDownloadButtonState();
}

class _PdfDownloadButtonState extends State<PdfDownloadButton> {
  bool _busy = false;

  Future<void> _handle() async {
    setState(() => _busy = true);
    try {
      final bytes = await widget.download();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.fileName}');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _handle,
      icon: _busy
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(LucideIcons.download, size: 16),
      label: Text(_busy ? 'Preparing...' : 'Download PDF'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.saffron600,
        side: const BorderSide(color: AppColors.saffron400),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
