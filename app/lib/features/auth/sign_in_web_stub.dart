import 'package:flutter/widgets.dart';

/// Phones use their own Google button (login_screen.dart); only the web renders Google's.
Widget googleWebButton(String lang) => const SizedBox.shrink();

/// Phones have Apple's sheet built in.
Future<void> loadAppleSignIn() async {}
