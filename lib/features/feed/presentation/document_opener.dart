import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/post.dart';
import 'document_card.dart';

/// PDF-et az appban nyit, minden mást a telefon alkalmazásával.
Future<void> openPostDocument(BuildContext context, PostMedia media) async {
  final name = media.name ?? 'dokumentum';
  final mime = media.mimeType ?? 'application/octet-stream';
  final progress = ValueNotifier<double?>(null);
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        content: ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (context, value, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Letöltés…'),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: value),
              ],
            );
          },
        ),
      );
    },
  );
  try {
    final file = await _download(media.url, name, (fraction) {
      progress.value = fraction;
    });
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!context.mounted) return;
    if (mime == 'application/pdf' || name.toLowerCase().endsWith('.pdf')) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PdfDocumentPage(file: file, name: name),
        ),
      );
      return;
    }
    final result = await OpenFilex.open(file.path, type: mime);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A telefon nem tudta megnyitni a dokumentumot.'),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A dokumentum letöltése nem sikerült.')),
      );
    }
  } finally {
    progress.dispose();
  }
}

Future<File> _download(
  String url,
  String name,
  void Function(double fraction) onProgress,
) async {
  final directory = await getTemporaryDirectory();
  final safe = name.replaceAll(RegExp(r'[\\/]+'), '_');
  final file = File('${directory.path}/$safe');
  final task = FirebaseStorage.instance.refFromURL(url).writeToFile(file);
  final subscription = task.snapshotEvents.listen((snapshot) {
    final total = snapshot.totalBytes;
    if (total <= 0) return;
    onProgress(snapshot.bytesTransferred / total);
  });
  try {
    await task;
    return file;
  } finally {
    await subscription.cancel();
  }
}

class PdfDocumentPage extends StatefulWidget {
  const PdfDocumentPage({required this.file, required this.name, super.key});

  final File file;
  final String name;

  @override
  State<PdfDocumentPage> createState() => _PdfDocumentPageState();
}

class _PdfDocumentPageState extends State<PdfDocumentPage> {
  late final PdfControllerPinch _controller = PdfControllerPinch(
    document: PdfDocument.openFile(widget.file.path),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() {
    return SharePlus.instance.share(
      ShareParams(files: [XFile(widget.file.path, name: widget.name)]),
    );
  }

  Future<void> _save() async {
    final bytes = await widget.file.readAsBytes();
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Mentés',
      fileName: widget.name,
      bytes: bytes,
      mimeType: 'application/pdf',
    );
    if (!mounted || saved == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Dokumentum mentve')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(middleEllipsis(widget.name, max: 24)),
        actions: [
          IconButton(
            tooltip: 'Megosztás',
            onPressed: _share,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Mentés',
            onPressed: _save,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: PdfViewPinch(controller: _controller),
    );
  }
}
