import 'package:flutter/material.dart';

class ExpandableFabAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  ExpandableFabAction({required this.icon, required this.label, required this.onTap});
}

/// A Material-style expandable FAB: tap the main button to reveal a
/// vertical stack of labeled mini-actions with a staggered scale/fade in.
class ExpandableFab extends StatefulWidget {
  final List<ExpandableFabAction> actions;
  final IconData icon;
  final IconData closeIcon;

  const ExpandableFab({
    super.key,
    required this.actions,
    this.icon = Icons.add,
    this.closeIcon = Icons.close,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  bool _isOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < widget.actions.length; i++)
          _buildMiniAction(widget.actions[widget.actions.length - 1 - i], i),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.rotate(
              angle: _controller.value * 0.75,
              child: Icon(_isOpen ? widget.closeIcon : widget.icon),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAction(ExpandableFabAction action, int index) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Interval((index / widget.actions.length) * 0.5, 1.0, curve: Curves.easeOutBack),
      ),
      child: FadeTransition(
        opacity: _controller,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                ),
                child: Text(action.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              FloatingActionButton.small(
                heroTag: action.label,
                onPressed: () {
                  _toggle();
                  action.onTap();
                },
                child: Icon(action.icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
