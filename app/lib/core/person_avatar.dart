import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// A person's photo in a circle (BoxFit.cover), or the first letter of [name] when there is none, it can't be loaded
/// or [userId] is null (a placeholder).
class PersonAvatar extends ConsumerWidget {
  final String? userId;
  final String name;
  final double radius;
  const PersonAvatar({super.key, required this.userId, required this.name, this.radius = 20});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bytes = userId == null ? null : ref.watch(avatarProvider(userId!)).value;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: userId == null ? cs.surfaceContainerHighest : cs.primaryContainer,
      foregroundColor: userId == null ? cs.onSurfaceVariant : cs.onPrimaryContainer,
      child: bytes == null
          ? Text(initial, style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w600))
          : ClipOval(child: Image.memory(bytes, width: radius * 2, height: radius * 2, fit: BoxFit.cover, gaplessPlayback: true)),
    );
  }
}
