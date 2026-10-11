import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/activity/activity_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/name_screen.dart';
import 'features/expense_form/expense_form_screen.dart';
import 'features/group_detail/group_detail_screen.dart';
import 'features/group_settings/group_settings_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/groups/join_code_screen.dart';
import 'features/groups/join_screen.dart';
import 'features/members/members_screen.dart';
import 'features/settings/payment_methods_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settle/settle_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects on any session change (sign-in, sign-out, name saved).
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/',
    redirect: (_, state) {
      final s = ref.read(sessionProvider).value;
      final loc = state.matchedLocation;
      if (s == null) return loc == '/login' ? null : '/login';
      if (needsDisplayName(s)) return loc == '/name' ? null : '/name';
      return loc == '/login' ? '/' : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/name', builder: (_, _) => const NameScreen()),
      // Children of '/': the groups list is always underneath, so every screen has a way back.
      GoRoute(
        path: '/',
        builder: (_, _) => const GroupsScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (_, _) => const SettingsScreen(),
            routes: [GoRoute(path: 'payment-methods', builder: (_, _) => const PaymentMethodsScreen())],
          ),
          GoRoute(path: 'activity', builder: (_, _) => const ActivityScreen()),
          GoRoute(path: 'join-code', builder: (_, _) => const JoinCodeScreen()),
          GoRoute(path: 'join/:code', builder: (_, s) => JoinScreen(code: s.pathParameters['code']!)),
          GoRoute(
            path: 'groups/:id',
            builder: (_, s) => GroupDetailScreen(groupId: s.pathParameters['id']!, tab: s.uri.queryParameters['tab']),
            routes: [
              GoRoute(path: 'members', builder: (_, s) => MembersScreen(groupId: s.pathParameters['id']!)),
              GoRoute(path: 'settle', builder: (_, s) => SettleScreen(groupId: s.pathParameters['id']!)),
              GoRoute(path: 'settings', builder: (_, s) => GroupSettingsScreen(groupId: s.pathParameters['id']!)),
              GoRoute(path: 'expenses/new', builder: (_, s) => ExpenseFormScreen(groupId: s.pathParameters['id']!)),
              GoRoute(
                path: 'expenses/:eid',
                builder: (_, s) => ExpenseFormScreen(groupId: s.pathParameters['id']!, expenseId: s.pathParameters['eid']),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
