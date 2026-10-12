import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Google Identity Services' own button: on the web the sign-in starts from it (no `authenticate()`), and the result
/// arrives in `GoogleSignIn.instance.authenticationEvents` (AuthService.initGoogleWeb).
Widget googleWebButton(String lang) => web.renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.pill,
        minimumWidth: 320,
        locale: lang,
      ),
    );

Future<void>? _apple;

/// Apple's sign-in script (allowed by the server's CSP), added only once this server says it offers Sign in with Apple
/// (`GET /info`): a page without it never contacts Apple. Tried again after a failed load.
Future<void> loadAppleSignIn() => _apple ??= () {
      final done = Completer<void>();
      final script = _createElement('script')
        ..onload = ((JSAny? _) => done.complete()).toJS
        ..onerror = ((JSAny? e) {
          _apple = null;
          done.completeError(StateError("Couldn't load Sign in with Apple"));
        }).toJS
        ..src = 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js';
      _appendToHead(script);
      return done.future;
    }();

extension type _Script._(JSObject _) implements JSObject {
  external set src(String value);
  external set onload(JSFunction value);
  external set onerror(JSFunction value);
}

@JS('document.createElement')
external _Script _createElement(String tag);

@JS('document.head.appendChild')
external void _appendToHead(_Script node);
