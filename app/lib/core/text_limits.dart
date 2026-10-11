import 'package:flutter/material.dart';

/// Server limits (docs/API.md 글자 수) count UTF-16 units, Dart's `String.length`. Flutter's `maxLength` counts
/// characters as seen (an emoji is 1), so name fields use [limitedDecoration] instead.
const maxGroupName = 100;
const maxMemberName = 100;

/// Whether the trimmed [text] fits [max] UTF-16 units.
bool fitsLimit(String text, int max) => text.trim().length <= max;

/// [d] with a `n/max` counter once the trimmed [text] is within 20 of [max], and "Too long" past it.
InputDecoration limitedDecoration(InputDecoration d, String text, int max) {
  final n = text.trim().length;
  return d.copyWith(counterText: n > max - 20 ? '$n/$max' : null, errorText: n > max ? 'Too long' : null);
}
