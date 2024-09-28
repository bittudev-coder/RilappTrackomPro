
import 'package:flutter/material.dart';
import 'package:gpspro/theme/CustomColor.dart';

class RatingBar extends StatelessWidget {
  final double initialRating;
  final Function(double) onRatingChanged;

  RatingBar({
    required this.initialRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final rating = index + 1.0;
        return IconButton(
          icon: Icon(
            rating <= initialRating ? Icons.star : Icons.star_border,
            color:color[400],
            size: 40,
          ),
          onPressed: () => onRatingChanged(rating),
        );
      }),
    );
  }
}
