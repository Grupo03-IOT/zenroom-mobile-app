import 'package:flutter/material.dart';
import '../../core/l10n/zenroom_i18n.dart';
import '../../core/legal/legal_document.dart';
import '../../core/theme/zenroom_theme.dart';
import '../app_controller.dart';
import '../widgets/zen_widgets.dart';
import 'home_shell.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.title, this.controller});

  /// `Terms of Service` o `Privacy Policy`.
  final String title;
  final AppController? controller;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late final Future<LegalDocuments> documents = LegalDocuments.load();
  final _sectionKeys = <String, GlobalKey>{};

  String get kind => widget.title == 'Privacy Policy' ? 'privacy' : 'terms';

  GlobalKey _keyOf(String id) => _sectionKeys.putIfAbsent(id, GlobalKey.new);

  void _goTo(String id) {
    final target = _keyOf(id).currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: LText(widget.title),
      backgroundColor: ZenColors.background,
    ),
    bottomNavigationBar: widget.controller?.signedIn == true
        ? ZenBottomNav(controller: widget.controller!)
        : null,
    body: FutureBuilder<LegalDocuments>(
      future: documents,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        if (loaded == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _document(loaded.of(kind, ZenroomI18n.languageOf(context)));
      },
    ),
  );

  // Todo el documento se construye a la vez para que el índice pueda saltar a
  // cualquier sección.
  Widget _document(LegalDocument document) => SelectionArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                document.effective,
                style: const TextStyle(fontSize: 12, color: ZenColors.muted),
              ),
              _paragraph(document.intro),
              const SizedBox(height: 16),
              _contents(document),
              for (final section in document.sections) ...[
                Padding(
                  key: _keyOf(section.id),
                  padding: const EdgeInsets.only(top: 24),
                  child: Semantics(
                    header: true,
                    child: Text(
                      section.heading,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ZenColors.navy,
                      ),
                    ),
                  ),
                ),
                for (final block in section.body)
                  if (block is List)
                    for (final item in block) _bullet(item as String)
                  else
                    _paragraph(block as String),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _contents(LegalDocument document) => ZenCard(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LText(
            'Contents',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        for (final section in document.sections)
          InkWell(
            key: ValueKey('legal-contents-${section.id}'),
            onTap: () => _goTo(section.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                section.heading,
                style: const TextStyle(
                  fontSize: 13,
                  color: ZenColors.navy,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _paragraph(String text) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
  );

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, left: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: TextStyle(fontSize: 14, height: 1.5)),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
      ],
    ),
  );
}
