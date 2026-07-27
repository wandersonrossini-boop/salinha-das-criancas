import 'package:flutter/material.dart';

class MascotWidget extends StatelessWidget {
  final String asset;
  final double width;
  final double? height;

  const MascotWidget({
    super.key,
    required this.asset,
    this.width = 120,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
      ),
    );
  }
}

