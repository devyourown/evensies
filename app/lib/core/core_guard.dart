/// Runs one of the TODO(효준) core functions; null while it is still unimplemented.
T? tryCore<T>(T Function() f) {
  try {
    return f();
  } on UnimplementedError {
    return null;
  }
}

const notImplementedLabel = '정산 로직 미구현 / not implemented';
