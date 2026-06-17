import 'package:flutter/widgets.dart';

class LayoutBreakpoints {
  LayoutBreakpoints._();

  static const double small = 360;
  static const double large = 600;

  static bool isSmall(BuildContext context) {
    return MediaQuery.sizeOf(context).width < small;
  }

  static bool isLarge(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= large;
  }

  static double contentMaxWidth(BuildContext context) {
    return isLarge(context) ? 560 : double.infinity;
  }
}
