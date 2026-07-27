import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorState({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
        ],
      ),
    );
  }
}
