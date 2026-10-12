import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/activity/activity_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/name_screen.dart';
import 'features/expense_detail/expense_detail_screen.dart';
import 'features/expense_form/expense_form_screen.dart';
import 'features/friends/add_friend_screen.dart';
import 'features/friends/friend_screen.dart';
import 'features/friends/friend_settle_screen.dart';
import 'features/friends/with_picker.dart';
import 'features/group_detail/group_detail_screen.dart';
import 'features/group_settings/group_settings_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/groups/join_code_screen.dart';
import 'features/groups/join_screen.dart';
import 'features/insights/insights_screen.dart';
import 'features/members/members_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/payment_methods_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settle/payment_detail_screen.dart';
import 'features/settle/settle_screen.dart';
import 'data/db/database.dart' show SessionRow;
import 'providers.dart';

/// A `next` that stays in the app: a path (`/join/K7P4QX`), never another origin (`//evil.example`, `https:`).
String? safeNext(String? next) => next != null && next.startsWith('/') && !next.startsWith('//') ? next : null;

/// Where a location goes before and after sign-in (docs/API.md 로그인 뒤 돌아가기): signed out → `/login?next=<it>`
/// (a landing page's `/app/#/join/K7P4QX` too), then the name screen if needed (keeping `next`), then `next`.
String? authRedirect(SessionRow? s, String loc, Uri uri) {
  Uri withNext(String path, String? next) =>
      Uri(path: path, queryParameters: next == null || next == '/' ? null : {'next': next});
  final next = loc == '/login' || loc == '/name' ? safeNext(uri.queryParameters['next']) : uri.toString();
  if (s == null) return loc == '/login' ? null : withNext('/login', next).toString();
  if (needsDisplayName(s)) return loc == '/name' ? null : withNext('/name', next).toString();
  return loc == '/login' ? next ?? '/' : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects on any session change (sign-in, sign-out, name saved).
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  // A friend group has exactly two members, no Leave and no settings (docs/API.md 친구): an activity row or a link to
  // its members or settings lands on the friend's page instead.
  Future<String?> friendPage(BuildContext _, GoRouterState s) async {
    final id = s.pathParameters['id']!;
    return (await ref.read(dbProvider).getGroup(id))?.kind == 'friend' ? '/groups/$id' : null;
  }

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/',
    redirect: (_, state) => authRedirect(ref.read(sessionProvider).value, state.matchedLocation, state.uri),
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/name', builder: (_, _) => const NameScreen()),
      // Children of '/': the groups list is always underneath, so every screen has a way back.
      GoRoute(
        path: '/',
        builder: (_, s) => GroupsScreen(key: ValueKey(s.uri.queryParameters['tab']), tab: s.uri.queryParameters['tab']),
        routes: [
          // Friends (docs/API.md 친구): the tab, adding one, a person's page (key = userId, g:<groupId>, m:<memberId>).
          GoRoute(path: 'friends', redirect: (_, _) => '/?tab=friends'),
          GoRoute(path: 'friends/add', builder: (_, s) => AddFriendScreen(code: s.uri.queryParameters['code'])),
          GoRoute(
            path: 'friends/:key',
            builder: (_, s) => FriendScreen(personKey: s.pathParameters['key']!),
            routes: [
              GoRoute(path: 'settle', builder: (_, s) => FriendSettleScreen(personKey: s.pathParameters['key']!)),
            ],
          ),
          // Add expense from Home: with whom first.
          GoRoute(path: 'expenses/new', builder: (_, _) => const NewExpenseScreen()),
          GoRoute(
            path: 'settings',
            builder: (_, _) => const SettingsScreen(),
            routes: [GoRoute(path: 'payment-methods', builder: (_, _) => const PaymentMethodsScreen())],
          ),
          GoRoute(path: 'activity', builder: (_, _) => const ActivityScreen()),
          GoRoute(
            path: 'search',
            builder: (_, s) => SearchScreen(
              groupId: s.uri.queryParameters['group'],
              category: s.uri.queryParameters['category'],
              month: s.uri.queryParameters['month'],
            ),
          ),
          GoRoute(path: 'join-code', builder: (_, _) => const JoinCodeScreen()),
          GoRoute(path: 'join/:code', builder: (_, s) => JoinScreen(code: s.pathParameters['code']!)),
          GoRoute(
            path: 'groups/:id',
            builder: (_, s) => GroupDetailScreen(groupId: s.pathParameters['id']!, tab: s.uri.queryParameters['tab']),
            routes: [
              GoRoute(
                  path: 'members',
                  redirect: friendPage,
                  builder: (_, s) => MembersScreen(groupId: s.pathParameters['id']!)),
              GoRoute(path: 'settle', builder: (_, s) => SettleScreen(groupId: s.pathParameters['id']!)),
              GoRoute(
                  path: 'settings',
                  redirect: friendPage,
                  builder: (_, s) => GroupSettingsScreen(groupId: s.pathParameters['id']!)),
              GoRoute(path: 'expenses/new', builder: (_, s) => ExpenseFormScreen(groupId: s.pathParameters['id']!)),
              GoRoute(path: 'insights', builder: (_, s) => InsightsScreen(groupId: s.pathParameters['id']!)),
              GoRoute(
                path: 'payments/:pid',
                builder: (_, s) =>
                    PaymentDetailScreen(groupId: s.pathParameters['id']!, paymentId: s.pathParameters['pid']!),
              ),
              // The read-only expense (list and activity taps land here); Edit opens the form.
              GoRoute(
                path: 'expenses/:eid',
                builder: (_, s) =>
                    ExpenseDetailScreen(groupId: s.pathParameters['id']!, expenseId: s.pathParameters['eid']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) =>
                        ExpenseFormScreen(groupId: s.pathParameters['id']!, expenseId: s.pathParameters['eid']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
