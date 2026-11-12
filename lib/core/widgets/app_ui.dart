import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';

class AppSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const AppSearchField(
      {super.key, required this.hint, required this.onChanged});

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        style: AppTheme.bodyMedium,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          isDense: true,
          constraints: const BoxConstraints(minHeight: 48),
          prefixIcon: const Icon(LucideIcons.search, size: 19),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                ),
        ),
      );
}

class AppFilterBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const AppFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options
              .map((option) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(option),
                      selected: option == selected,
                      showCheckmark: false,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      labelStyle: AppTheme.labelMedium.copyWith(
                        color: option == selected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      onSelected: (_) => onSelected(option),
                    ),
                  ))
              .toList(),
        ),
      );
}

class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const AppStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 156),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.labelMedium.copyWith(color: color)),
      );
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 28, color: AppTheme.textDisabled),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: AppTheme.bodyMedium),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ]),
      );
}
