import 'package:flutter/widgets.dart';

int getCrossAxisCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 1200) return 6;
  if (width > 900) return 5;
  if (width > 600) return 4;
  if (width > 400) return 3;
  return 2;
}
