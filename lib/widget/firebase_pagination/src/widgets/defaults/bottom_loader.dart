// Flutter Packages
import 'package:driver/themes/responsive.dart';
import 'package:flutter/material.dart';

/// A circular progress indicator that spins when the [Stream] is loading.
///
/// Used at the bottom of a [ScrollView] to indicate that more data is loading.
class BottomLoader extends StatelessWidget {
  /// Creates a circular progress indicator that spins when the [Stream] is
  /// loading.
  ///
  /// Used at the bottom of a [ScrollView] to indicate that more data is
  /// loading.
  const BottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: Responsive.width(6, context),
        height: Responsive.width(6, context),
        margin: EdgeInsets.all(Responsive.width(2.5, context)),
        child: CircularProgressIndicator.adaptive(
          strokeWidth: Responsive.width(0.6, context),
        ),
      ),
    );
  }
}
