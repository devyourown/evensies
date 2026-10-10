/// Runs a core function; null if it throws UnimplementedError (defensive, all core functions are implemented).
T? tryCore<T>(T Function() f) {
  try {
    return f();
  } on UnimplementedError {
    return null;
  }
}

const notImplementedLabel = '정산 로직 미구현 / not implemented';
