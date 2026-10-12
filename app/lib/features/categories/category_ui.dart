import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../domain/categories.dart';

/// Material icons by the names in categories.json (Flutter can't look an icon up by name at runtime).
const categoryIcons = <String, IconData>{
  'account_balance_outlined': Icons.account_balance_outlined,
  'bolt': Icons.bolt,
  'build_outlined': Icons.build_outlined,
  'card_giftcard': Icons.card_giftcard,
  'chair_outlined': Icons.chair_outlined,
  'checkroom': Icons.checkroom,
  'child_friendly_outlined': Icons.child_friendly_outlined,
  'cleaning_services_outlined': Icons.cleaning_services_outlined,
  'commute': Icons.commute,
  'devices_outlined': Icons.devices_outlined,
  'directions_car_outlined': Icons.directions_car_outlined,
  'favorite_outline': Icons.favorite_outline,
  'flight': Icons.flight,
  'handyman_outlined': Icons.handyman_outlined,
  'home_outlined': Icons.home_outlined,
  'hotel_outlined': Icons.hotel_outlined,
  'house_outlined': Icons.house_outlined,
  'inventory_2_outlined': Icons.inventory_2_outlined,
  'lightbulb_outline': Icons.lightbulb_outline,
  'local_activity_outlined': Icons.local_activity_outlined,
  'local_bar': Icons.local_bar,
  'local_fire_department_outlined': Icons.local_fire_department_outlined,
  'local_gas_station_outlined': Icons.local_gas_station_outlined,
  'local_parking': Icons.local_parking,
  'local_taxi_outlined': Icons.local_taxi_outlined,
  'medical_services_outlined': Icons.medical_services_outlined,
  'movie_outlined': Icons.movie_outlined,
  'music_note': Icons.music_note,
  'pedal_bike': Icons.pedal_bike,
  'pets': Icons.pets,
  'receipt_outlined': Icons.receipt_outlined,
  'recycling': Icons.recycling,
  'request_quote_outlined': Icons.request_quote_outlined,
  'restaurant': Icons.restaurant,
  'restaurant_menu': Icons.restaurant_menu,
  'school_outlined': Icons.school_outlined,
  'shield_outlined': Icons.shield_outlined,
  'shopping_cart_outlined': Icons.shopping_cart_outlined,
  'sports_esports': Icons.sports_esports,
  'sports_soccer': Icons.sports_soccer,
  'train_outlined': Icons.train_outlined,
  'water_drop_outlined': Icons.water_drop_outlined,
  'wifi': Icons.wifi,
};

/// The icon a stored value shows (General's for null and legacy text).
IconData categoryIcon(String? raw) => categoryIcons[Categories.of(raw)?.icon] ?? Icons.receipt_outlined;

/// Background and foreground of a category tile: one theme container color per parent, so a list scans by kind.
/// [raw] is a stored value, or a parent key when [parent] is set.
(Color, Color) categoryColors(ColorScheme cs, String? raw, {bool parent = false}) {
  final key = parent ? raw : Categories.of(raw)?.parent;
  final i = Categories.parents.indexWhere((p) => p.key == key);
  if (key == null || key == 'uncategorized' || i < 0) return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
  return switch (i % 3) {
    0 => (cs.primaryContainer, cs.onPrimaryContainer),
    1 => (cs.secondaryContainer, cs.onSecondaryContainer),
    _ => (cs.tertiaryContainer, cs.onTertiaryContainer),
  };
}

/// A rounded tile with the category icon, like Splitwise's list rows.
class CategoryAvatar extends StatelessWidget {
  /// A stored value (a parent key stored as text is legacy and shows General), or a parent key with [parent].
  final String? category;
  final double size;
  final bool parent;
  const CategoryAvatar(this.category, {super.key, this.size = 40}) : parent = false;
  const CategoryAvatar.parent(String this.category, {super.key, this.size = 40}) : parent = true;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = categoryColors(Theme.of(context).colorScheme, category, parent: parent);
    final icon = parent ? categoryIcons[Categories.parent(category!)?.icon] : categoryIcon(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size / 4)),
      child: Icon(icon ?? Icons.receipt_outlined,
          size: size * 0.55,
          color: fg,
          semanticLabel: parent ? Categories.nameOf(category!) : Categories.labelOf(category)),
    );
  }
}

/// Bottom sheet with every category under its parent; returns the picked key, or null when dismissed.
/// With [parents] each section also offers "All {parent}" (returns the parent key), for search filters.
Future<String?> showCategoryPicker(BuildContext context, {String? current, bool parents = false}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        Widget chip(String key, String label, IconData icon) => ChoiceChip(
              key: Key('category-$key'),
              avatar: Icon(icon, size: 18),
              label: Text(label),
              selected: key == current,
              onSelected: (_) => Navigator.pop(context, key),
            );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(parents ? context.l.filterByCategory : context.l.category, style: text.titleLarge),
              for (final p in Categories.parents) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: Row(children: [
                    Icon(categoryIcons[p.icon], size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(Categories.nameOf(p.key), style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                ),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  if (parents) chip(p.key, context.l.categoryAll, Icons.select_all),
                  for (final c in Categories.under(p.key)) chip(c.key, Categories.nameOf(c.key), categoryIcons[c.icon]!),
                ]),
              ],
            ],
          ),
        );
      },
    );
