import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < 8; i++) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              height: 65.0,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            const SizedBox(height: 4.0),
          ],
          for (int i = 0; i < 2; i++) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              height: 48.0,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ],
        ],
      ),
    );
  }
}