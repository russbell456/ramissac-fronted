import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'file_writer.dart';
import 'package:printing/printing.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String filename;
  const DocumentPreviewScreen(
      {super.key, required this.bytes, required this.filename});

  Future<void> _guardar(BuildContext context) async {
    try {
      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: filename);
        return;
      }
      final writesBytes = defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
      final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar PDF',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: writesBytes ? bytes : null);
      if (!writesBytes && path != null) await writePdfFile(path, bytes);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo guardar el PDF: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(filename), actions: [
          IconButton(
              tooltip: 'Imprimir PDF',
              icon: const Icon(Icons.print_outlined),
              onPressed: () async {
                try {
                  await Printing.layoutPdf(
                      name: filename, onLayout: (_) async => bytes);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo imprimir: $error')));
                  }
                }
              }),
          IconButton(
              tooltip: 'Descargar PDF',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _guardar(context)),
        ]),
        body: PdfPreview.builder(
            pagesBuilder: (context, pages) => _PdfPages(pages: pages),
            build: (_) async => bytes,
            allowPrinting: false,
            allowSharing: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            useActions: false,
            dpi: 160,
            maxPageWidth: 950),
      );
}

class _PdfPages extends StatefulWidget {
  final List<PdfPreviewPageData> pages;
  const _PdfPages({required this.pages});
  @override
  State<_PdfPages> createState() => _PdfPagesState();
}

class _PdfPagesState extends State<_PdfPages> {
  final _pageController = PageController();
  final _transform = TransformationController();
  int _page = 0;

  void _zoom(double factor, Size viewport) {
    final scale =
        (_transform.value.getMaxScaleOnAxis() * factor).clamp(1.0, 6.0);
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(viewport.width * (1 - scale) / 2,
          viewport.height * (1 - scale) / 2, 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final viewport = Size(bounds.maxWidth, bounds.maxHeight - 48);
        return Column(children: [
          Expanded(
              child: PageView.builder(
            controller: _pageController,
            itemCount: widget.pages.length,
            onPageChanged: (page) {
              _transform.value = Matrix4.identity();
              setState(() => _page = page);
            },
            itemBuilder: (context, index) => InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              maxScale: 6,
              child: Center(
                  child: AspectRatio(
                aspectRatio: widget.pages[index].aspectRatio,
                child: ColoredBox(
                    color: Colors.white,
                    child: Image(
                        image: widget.pages[index].image, fit: BoxFit.contain)),
              )),
            ),
          )),
          SizedBox(
              height: 48,
              child: ColoredBox(
                color: Colors.white,
                child: Row(children: [
                  IconButton(
                      tooltip: 'Página anterior',
                      onPressed: _page == 0
                          ? null
                          : () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut),
                      icon: const Icon(Icons.chevron_left)),
                  Text('${_page + 1} / ${widget.pages.length}',
                      style: const TextStyle(fontSize: 12)),
                  IconButton(
                      tooltip: 'Página siguiente',
                      onPressed: _page + 1 >= widget.pages.length
                          ? null
                          : () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut),
                      icon: const Icon(Icons.chevron_right)),
                  const Spacer(),
                  IconButton(
                      tooltip: 'Alejar',
                      onPressed: () => _zoom(1 / 1.5, viewport),
                      icon: const Icon(Icons.zoom_out)),
                  IconButton(
                      tooltip: 'Acercar',
                      onPressed: () => _zoom(1.5, viewport),
                      icon: const Icon(Icons.zoom_in)),
                  IconButton(
                      tooltip: 'Ajustar página',
                      onPressed: () => _transform.value = Matrix4.identity(),
                      icon: const Icon(Icons.fit_screen)),
                ]),
              )),
        ]);
      });
}
