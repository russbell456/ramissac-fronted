import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';

class RqSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  const RqSection(
      {super.key,
      required this.title,
      this.subtitle,
      required this.child,
      this.action});

  @override
  Widget build(BuildContext context) => Material(
        color: AppTheme.surface,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(title, style: AppTheme.titleMedium),
                  if (action != null) action!,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppTheme.bodySmall)
              ],
              const SizedBox(height: 12),
              child,
            ])),
      );
}

class RqFooter extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Widget? secondary;
  const RqFooter(
      {super.key,
      required this.label,
      this.onPressed,
      this.busy = false,
      this.secondary});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.border))),
        child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Row(children: [
                        if (secondary != null) ...[
                          Expanded(flex: 2, child: secondary!),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                            flex: 3,
                            child: FilledButton(
                                onPressed: busy ? null : onPressed,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (busy) ...[
                                        const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)),
                                        const SizedBox(width: 8)
                                      ],
                                      Flexible(
                                          child: Text(label,
                                              textAlign: TextAlign.center)),
                                    ]))),
                      ]))),
            )),
      );
}

class StockLabel extends StatelessWidget {
  final num stock;
  final String unit;
  const StockLabel({super.key, required this.stock, this.unit = ''});
  @override
  Widget build(BuildContext context) => Text(
        stock > 0
            ? 'Stock: $stock $unit'.trim()
            : 'Sin stock · se puede solicitar',
        style: TextStyle(
            fontSize: 12,
            color: stock > 0 ? const Color(0xFF426719) : AppTheme.textSecondary,
            fontWeight: FontWeight.w500),
      );
}
