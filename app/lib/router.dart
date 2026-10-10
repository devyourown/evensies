import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/login_screen.dart';
import 'features/expense_form/expense_form_screen.dart';
import 'features/group_detail/group_detail_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/groups/join_screen.dart';
import 'features/members/members_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settle/settle_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ValueNotifier<bool>(ref.read(sessionProvider).value != null);
  ref.listen(sessionProvider, (_, next) => loggedIn.value = next.value != null);
  return GoRouter(
    refreshListenable: loggedIn,
    initialLocation: '/',
    redirect: (_, state) {
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn.value) return atLogin ? null : '/login';
      return atLogin ? '/' : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const GroupsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/join/:code', builder: (_, s) => JoinScreen(code: s.pathParameters['code']!)),
      GoRoute(path: '/groups/:id', builder: (_, s) => GroupDetailScreen(groupId: s.pathParameters['id']!)),
      GoRoute(path: '/groups/:id/members', builder: (_, s) => MembersScreen(groupId: s.pathParameters['id']!)),
      GoRoute(path: '/groups/:id/settle', builder: (_, s) => SettleScreen(groupId: s.pathParameters['id']!)),
      GoRoute(path: '/groups/:id/expenses/new', builder: (_, s) => ExpenseFormScreen(groupId: s.pathParameters['id']!)),
      GoRoute(
        path: '/groups/:id/expenses/:eid',
        builder: (_, s) => ExpenseFormScreen(groupId: s.pathParameters['id']!, expenseId: s.pathParameters['eid']),
      ),
    ],
  );
});
