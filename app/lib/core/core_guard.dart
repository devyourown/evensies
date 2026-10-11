/// Runs a core function; null if it throws UnimplementedError (defensive, all core functions are implemented).
T? tryCore<T>(T Function() f) {
  try {
    return f();
  } on UnimplementedError {
    return null;
  }
}

/// False only while [f] throws UnimplementedError (a TODO(효준) stub); any other result, other errors included, is true.
/// E.g. `implemented(() => computeSplit(amount: 0, mode: SplitMode.shares, members: const ['a'], input: const {'a': 0}))`.
bool implemented(void Function() f) {
  try {
    f();
  } on UnimplementedError {
    return false;
  } catch (_) {}
  return true;
}

/// Shown where a TODO(효준) core function is still a stub (정산 로직 미구현). Gone once his code lands.
const notImplementedLabel = 'Coming soon';
