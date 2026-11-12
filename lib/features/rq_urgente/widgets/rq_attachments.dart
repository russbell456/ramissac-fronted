import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'document_preview_screen.dart';

class RqAttachments extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final ValueChanged<int>? onRemove;
  const RqAttachments({super.key, required this.files, this.onRemove});

  @override
  Widget build(BuildContext context) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: files.asMap().entries.map((entry) {
        final a = entry.value;
        final image = (a['tipo_mime'] ?? '').toString().startsWith('image/') ||
            ['jpg', 'jpeg', 'png'].contains(a['extension']);
        final name = (a['nombre'] ?? 'Adjunto').toString();
        final bytes =
            base64Decode((a['contenido_base64'] ?? a['base64']).toString());
        return SizedBox(
            width: image ? 140 : 240,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image)
                      InkWell(
                          onTap: () => showDialog<void>(
                              context: context,
                              builder: (c) => Dialog(
                                      child: Stack(children: [
                                    Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: InteractiveViewer(
                                            child: Image.memory(bytes,
                                                fit: BoxFit.contain))),
                                    Positioned(
                                        right: 0,
                                        top: 0,
                                        child: IconButton(
                                            tooltip: 'Cerrar imagen',
                                            onPressed: () => Navigator.pop(c),
                                            icon: const Icon(Icons.close))),
                                  ]))),
                          child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              child: Image.memory(bytes,
                                  width: 140,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const SizedBox(
                                          height: 96,
                                          child: Center(
                                              child: Icon(Icons
                                                  .broken_image_outlined)))))),
                    Row(children: [
                      if (!image)
                        const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child:
                                Icon(Icons.picture_as_pdf_outlined, size: 20)),
                      Expanded(
                          child: InkWell(
                              onTap: image
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => DocumentPreviewScreen(
                                              bytes: bytes, filename: name))),
                              child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.bodySmall)))),
                      if (onRemove != null)
                        IconButton(
                            tooltip: 'Quitar adjunto',
                            onPressed: () => onRemove!(entry.key),
                            icon: const Icon(Icons.close, size: 18)),
                    ]),
                  ]),
            ));
      }).toList());
}
