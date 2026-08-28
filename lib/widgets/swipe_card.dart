import 'package:flutter/material.dart';

import '../models/game.dart';
import '../utils/image_url.dart';

enum SwipeDecision { behalten, verkaufen, spaeter }

/// Ein einzelnes, per Drag-Geste swipebares Spiele-Karte.
/// Rechts = Behalten, Links = Verkaufen, Hoch = Später entscheiden.
class SwipeCard extends StatefulWidget {
  final Game game;
  final void Function(SwipeDecision decision) onDecided;

  const SwipeCard({super.key, required this.game, required this.onDecided});

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  late final AnimationController _returnController;

  static const _swipeThreshold = 110.0;

  @override
  void initState() {
    super.initState();
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() {
          _drag = Offset.lerp(_drag, Offset.zero, _returnController.value)!;
        });
      });
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _drag += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_drag.dx > _swipeThreshold) {
      widget.onDecided(SwipeDecision.behalten);
    } else if (_drag.dx < -_swipeThreshold) {
      widget.onDecided(SwipeDecision.verkaufen);
    } else if (_drag.dy < -_swipeThreshold) {
      widget.onDecided(SwipeDecision.spaeter);
    } else {
      final start = _drag;
      _returnController
        ..value = 0
        ..forward();
      _drag = start;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rotation = (_drag.dx / 300).clamp(-0.4, 0.4);
    final behaltenOpacity = (_drag.dx / _swipeThreshold).clamp(0.0, 1.0);
    final verkaufenOpacity = (-_drag.dx / _swipeThreshold).clamp(0.0, 1.0);
    final spaeterOpacity = (-_drag.dy / _swipeThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: rotation,
          child: Card(
            elevation: 6,
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                Positioned.fill(
                  child: widget.game.coverImageUrl != null
                      ? Image.network(
                          corsProxiedImageUrl(widget.game.coverImageUrl)!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        )
                      : Container(color: theme.colorScheme.surfaceContainerHighest),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.game.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (widget.game.kaufpreis != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Kaufpreis: ${widget.game.kaufpreis!.toStringAsFixed(2)} €',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _stampel('BEHALTEN', Colors.green, behaltenOpacity,
                    alignment: Alignment.topLeft),
                _stampel('VERKAUFEN', Colors.red, verkaufenOpacity,
                    alignment: Alignment.topRight),
                _stampel('SPÄTER', Colors.orange, spaeterOpacity,
                    alignment: Alignment.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stampel(String text, Color color, double opacity,
      {required Alignment alignment}) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
