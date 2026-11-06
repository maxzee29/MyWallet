import 'package:flutter/widgets.dart';

import 'app_language.dart';

/// Membangun ulang seluruh tampilan saat bahasa berubah, tanpa menghapus
/// halaman yang sedang terbuka atau status yang tersimpan di dalamnya.
class AppLanguageRoot extends StatefulWidget {
  const AppLanguageRoot({
    super.key,
    required this.language,
    required this.child,
  });

  final AppLanguage language;
  final Widget child;

  @override
  State<AppLanguageRoot> createState() => _AppLanguageRootState();
}

class _AppLanguageRootState extends State<AppLanguageRoot> {
  @override
  void didUpdateWidget(AppLanguageRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildAll();
      });
    }
  }

  void _rebuildAll() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
