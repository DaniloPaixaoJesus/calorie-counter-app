import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

PageRoute<T> adaptivePageRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS) {
    return CupertinoPageRoute<T>(builder: builder);
  }

  return MaterialPageRoute<T>(builder: builder);
}
