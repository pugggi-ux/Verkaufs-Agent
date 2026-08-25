import 'package:flutter/material.dart';

/// Horizontale Balken-Visualisierung der Marktwert-Einschätzung:
/// `recherche_min` (links) bis `recherche_max` (rechts), mit Marker für
/// die Schmerzgrenze (innerhalb oder außerhalb der Range) sowie optional
/// dem gewählten Angebotspreis.
class PriceRangeBar extends StatelessWidget {
  final double min;
  final double max;
  final double? schmerzgrenze;
  final double? angebotspreis;

  const PriceRangeBar({
    super.key,
    required this.min,
    required this.max,
    this.schmerzgrenze,
    this.angebotspreis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domainMax = [
      max,
      if (schmerzgrenze != null) schmerzgrenze!,
      if (angebotspreis != null) angebotspreis!,
    ].reduce((a, b) => a > b ? a : b) *
        1.15;
    final domainMin = 0.0;
    final span = (domainMax - domainMin).clamp(1, double.infinity);

    double fraction(double value) => ((value - domainMin) / span).clamp(0.0, 1.0);

    final ueberschritten = schmerzgrenze != null && schmerzgrenze! > max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Hintergrund-Track
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Recherche-Range min..max
                  Positioned(
                    top: 16,
                    left: width * fraction(min),
                    width: (width * (fraction(max) - fraction(min))).clamp(4, width),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Schmerzgrenze-Marker
                  if (schmerzgrenze != null)
                    Positioned(
                      top: 6,
                      left: (width * fraction(schmerzgrenze!) - 1).clamp(0, width - 2),
                      child: Container(
                        width: 2,
                        height: 28,
                        color: ueberschritten
                            ? theme.colorScheme.error
                            : theme.colorScheme.tertiary,
                      ),
                    ),
                  // Angebotspreis-Marker
                  if (angebotspreis != null)
                    Positioned(
                      top: 0,
                      left: (width * fraction(angebotspreis!) - 6).clamp(0, width - 12),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.toStringAsFixed(0)} €', style: theme.textTheme.labelSmall),
            Text('${max.toStringAsFixed(0)} €', style: theme.textTheme.labelSmall),
          ],
        ),
        if (schmerzgrenze != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              ueberschritten
                  ? 'Schmerzgrenze ${schmerzgrenze!.toStringAsFixed(0)} € liegt über der Recherche-Range'
                  : 'Schmerzgrenze: ${schmerzgrenze!.toStringAsFixed(0)} €',
              style: theme.textTheme.labelSmall?.copyWith(
                color: ueberschritten ? theme.colorScheme.error : null,
              ),
            ),
          ),
      ],
    );
  }
}
