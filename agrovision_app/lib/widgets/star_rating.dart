import 'package:flutter/material.dart';

/// Reusable star rating widget
class StarRating extends StatefulWidget {
  final int rating;
  final ValueChanged<int> onRate;
  final int maxStars;

  const StarRating({
    super.key,
    required this.rating,
    required this.onRate,
    this.maxStars = 5,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int _hovered = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.maxStars, (index) {
        final starNum = index + 1;
        final filled = starNum <= (_hovered > 0 ? _hovered : widget.rating);
        return GestureDetector(
          onTap: () => widget.onRate(starNum),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = starNum),
            onExit: (_) => setState(() => _hovered = 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Transform.scale(
                scale: filled ? 1.15 : 1.0,
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 32,
                  color: filled ? Colors.amber : Colors.grey.withOpacity(0.4),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
