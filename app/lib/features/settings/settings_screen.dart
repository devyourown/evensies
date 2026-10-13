import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/appearance.dart';
import '../../core/browser_stub.dart' if (dart.library.js_interop) '../../core/browser_web.dart' show downloadFile;
import '../../core/confirm.dart';
import '../../core/currency_picker.dart';
import '../../core/env.dart';
import '../../core/ids.dart' show todayIso;
import '../../core/l10n.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../data/blob_store.dart' show tempDir;
import '../../data/db/database.dart';
import '../../data/images.dart';
import '../../providers.dart';
import '../auth/auth_service.dart';
import '../friends/home_data.dart';
import '../groups/wide_layout.dart' show isWide;
import '../lock/app_lock.dart';

/// Exports a group (a friend group: its non-group expenses) through the share sheet as `[name].[format]` (the browser
/// downloads it); `zip` is the JSON plus every receipt photo (Phase 7).
Future<void> exportGroup(BuildContext context, WidgetRef ref, String groupId, String name, String format) async {
  try {
    final api = ref.read(apiProvider);
    // A file name can't hold a slash.
    final fileName = '${name.replaceAll('/', '-')}.$format';
    final mime = switch (format) { 'zip' => 'application/zip', 'csv' => 'text/csv', _ => 'application/json' };
    final dir = format == 'zip' ? await tempDir() : null;
    if (dir != null) {
      // Phones: the ZIP streams into a temp file instead of memory.
      await api.exportZipTo(groupId, '$dir/$fileName');
      await SharePlus.instance.share(ShareParams(
          files: [XFile('$dir/$fileName', name: fileName, mimeType: mime)], fileNameOverrides: [fileName]));
      return;
    }
    final Uint8List bytes =
        format == 'zip' ? await api.exportZip(groupId) : utf8.encode(await api.export(groupId, format));
    await shareFile(bytes, fileName, mime);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

/// [bytes] as `fileName` through the share sheet; the browser downloads it.
Future<void> shareFile(Uint8List bytes, String fileName, String mime) async {
  if (kIsWeb) return downloadFile(bytes, fileName, mime);
  await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, name: fileName, mimeType: mime)], fileNameOverrides: [fileName]));
}

/// Export everything (docs/API.md `GET /me/export`): one JSON file with my profile, ways to get paid, settings and
/// every group, deleted ones included, as `evensies-export-YYYY-MM-DD.json`.
Future<void> exportAccount(BuildContext context, WidgetRef ref) async {
  try {
    final json = await ref.read(apiProvider).exportAccount();
    await shareFile(utf8.encode(json), 'evensies-export-${todayIso()}.json', 'application/json');
  } catch (e) {
    if (context.mounted) {
      showError(context, e is ApiException && e.code == 'NETWORK' ? context.l.exportNeedsConnection : e);
    }
  }
}

/// Help & feedback (docs/API.md, `EVENSIES_SUPPORT_EMAIL`): a GitHub issue, the operator's address when it has one, the privacy policy.
const issuesUrl = 'https://github.com/devyourown/evensies/issues/new';
const privacyUrl = 'https://devyourown.github.io/evensies/privacy';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _url = TextEditingController(text: ref.read(serverUrlProvider));

  /// GET/PUT /me/notifications; null while loading or when it failed ([_prefsFailed]). The switches are booleans,
  /// `emailDigest` / `emailDigestEffective` strings (Phase 10).
  Map<String, Object>? _prefs;
  bool _prefsFailed = false;
  bool _savingHome = false;
  bool _savingPhoto = false;
  int _homeTry = 0; // a refused change rebuilds the picker with the saved value
  static List<(String, String, IconData)> _prefLabels(AppLocalizations l) => [
        ('expenses', l.notifExpenses, Icons.receipt_long_outlined),
        ('comments', l.notifComments, Icons.chat_bubble_outline),
        ('members', l.notifMembers, Icons.group_outlined),
        // Only shown when the server has it (Phase 6): an older server would refuse the key.
        ('reminders', l.notifReminders, Icons.notifications_active_outlined),
      ];

  /// Take photo / Choose from library / Remove (docs/API.md, Profile photos), online only.
  Future<void> _photo(String userId) async {
    final hasPhoto = ref.read(avatarProvider(userId)).value != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // The browser picks a file (a phone's browser offers its camera there too).
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(ctx.l.photoTake),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(kIsWeb ? ctx.l.photoChooseFile : ctx.l.photoChoose),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          if (hasPhoto)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text(ctx.l.photoRemove, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    // Known offline: say so now, not after a photo was picked for nothing.
    if (ref.read(offlineProvider)) return showError(context, context.l.photoNeedsConnection);
    final api = ref.read(apiProvider);
    final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    try {
      if (choice == 'remove') {
        setState(() => _savingPhoto = true);
        await api.deleteAvatar();
      } else {
        final file = await ref
            .read(pickPhotoProvider)(source, maxEdge: 512, quality: 85);
        if (file == null) return;
        if (mounted) setState(() => _savingPhoto = true);
        await api.putAvatar(file);
      }
      ref.invalidate(avatarProvider(userId));
    } on ApiException catch (e) {
      if (mounted) {
        showError(
          context,
          switch (e) {
            ApiException(code: 'NETWORK') => context.l.photoNeedsConnection,
            ApiException(status: 429) => context.l.photoTooMany,
            _ => context.l.photoUnusable,
          },
        );
      }
    } catch (e) {
      if (mounted) showError(context, photoErrorText(context.l, e, source));
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    if (_prefsFailed) setState(() => _prefsFailed = false);
    try {
      final p = await ref.read(apiProvider).getNotificationPrefs();
      if (mounted) setState(() => _prefs = p);
    } catch (_) {
      if (mounted) setState(() => _prefsFailed = true);
    }
  }

  /// Optimistic; reverts when the server refuses or is unreachable. A switch sends the switches only (a missing
  /// `emailDigest` stays as saved); [key] `emailDigest` sends them with the new choice.
  Future<void> _setPref(String key, Object value) async {
    final old = _prefs!;
    setState(() => _prefs = {...old, key: value});
    try {
      final body = <String, Object>{
        for (final e in old.entries)
          if (e.value is bool) e.key: e.value,
        key: value,
      };
      final saved = await ref.read(apiProvider).putNotificationPrefs(body);
      if (mounted) setState(() => _prefs = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs = old);
      showError(context, context.l.notifSaveFailed);
    }
  }

  /// Email summary (docs/API.md, Summary emails): Auto, Daily, Weekly, Monthly or Off.
  Future<void> _pickDigest() async {
    final current = _prefs?['emailDigest'] as String? ?? 'auto';
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l.emailSummary),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final c in const ['auto', 'daily', 'weekly', 'monthly', 'off'])
                RadioListTile<String>(
                  key: Key('digest-$c'),
                  value: c,
                  title: Text(ctx.l.digestChoice(c)),
                  subtitle: c == 'auto' ? Text(ctx.l.digestAutoHelp) : null,
                ),
            ]),
          ),
        ],
      ),
    );
    if (picked != null && picked != current) await _setPref('emailDigest', picked);
  }

  /// "Auto — daily, because notifications are off", or the picked one.
  String _digestText(AppLocalizations l) {
    final choice = _prefs?['emailDigest'] as String? ?? 'auto';
    if (choice != 'auto') return l.digestChoice(choice);
    return switch (_prefs?['emailDigestEffective']) {
      'daily' => l.digestAutoDaily,
      'monthly' => l.digestAutoMonthly,
      _ => l.digestChoice('auto'),
    };
  }

  /// Opens [url] outside the app (GitHub, the privacy policy).
  Future<void> _open(String url) async {
    final l = context.l;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) showInfo(context, l.couldNotOpen(url));
  }

  /// PATCH /me, online only (docs/API.md): the session keeps what the server saved.
  Future<void> _setHome(String code) async {
    setState(() => _savingHome = true);
    try {
      final user = await ref.read(apiProvider).updateMe(homeCurrency: code);
      await ref.read(dbProvider).updateProfile(user.id, homeCurrency: user.homeCurrency ?? code);
    } catch (e) {
      if (!mounted) return;
      setState(() => _homeTry++);
      showError(context,
          e is ApiException && e.code == 'NETWORK' ? context.l.homeCurrencyNeedsConnection : e);
    } finally {
      if (mounted) setState(() => _savingHome = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Back online (a resume or the offline retry synced): what failed to load comes back without Retry.
    ref.listen(offlineProvider, (was, now) {
      if (was == true && !now && _prefsFailed) _loadPrefs();
    });
    final session = ref.watch(sessionProvider).value;
    final home = ref.watch(homeCurrencyProvider);
    final groups = ref.watch(groupsProvider).value ?? const <GroupRow>[];
    final homeData = ref.watch(homeDataProvider).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    String k(String text) => keepAll(text, l.localeName);
    final lockSupported = !kIsWeb && (ref.watch(lockSupportedProvider).value ?? false);
    final info = ref.watch(infoProvider);
    final deleted = ref.watch(deletedGroupsProvider).value ?? const <GroupRow>[];
    Widget header(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle), automaticallyImplyLeading: !isWide(context)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            leading: Semantics(
              button: true,
              label: l.changePhoto,
              child: InkWell(
                key: const Key('my-photo'),
                customBorder: const CircleBorder(),
                onTap: session == null || _savingPhoto ? null : () => _photo(session.userId),
                child: Stack(clipBehavior: Clip.none, children: [
                  PersonAvatar(userId: session?.userId, name: session?.displayName ?? '', radius: 24),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: cs.surface,
                      child: _savingPhoto
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.photo_camera, size: 14, color: cs.primary),
                    ),
                  ),
                ]),
              ),
            ),
            title: Text(session?.displayName ?? '-'),
            subtitle: Text(k(l.yourNameTapToChange)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => context.push('/name'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l.waysToGetPaid),
            subtitle: Text(k(l.waysToGetPaidHint)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/payment-methods'),
          ),
          ListTile(
            key: const Key('home-currency'),
            leading: const Icon(Icons.public),
            title: Text(l.homeCurrency),
            subtitle: Text(k(session?.homeCurrency == null ? l.homeCurrencyFromRegion : l.homeCurrencyPicked)),
            trailing: _savingHome
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : CurrencyPicker(
                    key: ValueKey('home-$_homeTry'),
                    value: home,
                    width: 124,
                    bare: true,
                    textStyle: text.titleMedium?.copyWith(color: cs.onSurface),
                    onChanged: _setHome,
                  ),
          ),
          header(l.notifications),
          for (final (key, label, icon) in _prefLabels(l))
            if (key != 'reminders' || (_prefs?.containsKey(key) ?? false))
              SwitchListTile(
                secondary: Icon(icon),
                title: Text(label),
                value: _prefs?[key] as bool? ?? true,
                onChanged: _prefs == null ? null : (v) => _setPref(key, v),
              ),
          // Phase 10, only when this server sends email and has the setting.
          if (info.emailLogin && (_prefs?.containsKey('emailDigest') ?? false))
            ListTile(
              key: const Key('email-digest'),
              leading: const Icon(Icons.mark_email_read_outlined),
              title: Text(l.emailSummary),
              subtitle: Text(k(session?.email == null ? l.digestNoEmail : _digestText(l))),
              enabled: session?.email != null,
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDigest,
            ),
          if (_prefsFailed)
            ListTile(
              leading: Icon(Icons.cloud_off_outlined, color: cs.onSurfaceVariant),
              title: Text(k(l.notifNeedConnection), style: TextStyle(color: cs.onSurfaceVariant)),
              trailing: TextButton(onPressed: _loadPrefs, child: Text(l.retry)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(k(kIsWeb ? l.notifWebNote : l.notifOthersOnly),
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          header(l.exportImport),
          ListTile(
            key: const Key('export-everything'),
            leading: const Icon(Icons.download_outlined),
            title: Text(l.exportEverything),
            subtitle: Text(k(l.exportEverythingHint)),
            onTap: () => exportAccount(context, ref),
          ),
          if (deleted.isNotEmpty)
            ListTile(
              key: const Key('deleted-groups'),
              leading: const Icon(Icons.restore_from_trash_outlined),
              title: Text(l.deletedGroups),
              subtitle: Text(l.deletedGroupsCount(deleted.length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/deleted'),
            ),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(k(l.noGroupsToExport), style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          for (final g in groups)
            ListTile(
              title: Text(g.kind == 'friend' ? homeData?.label(g.id, l) ?? l.nonGroup : g.name),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (v) => v == 'import'
                    ? _import(g)
                    : exportGroup(context, ref, g.id, g.kind == 'friend' ? homeData?.label(g.id, l) ?? g.name : g.name, v),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'json', child: Text(l.exportJson)),
                  PopupMenuItem(value: 'csv', child: Text(l.exportCsv)),
                  PopupMenuItem(value: 'zip', child: Text(l.exportZip)),
                  // A friend group has exactly two members, so new names from a file can't be added (409).
                  if (g.kind != 'friend') PopupMenuItem(value: 'import', child: Text(l.importSplitwise)),
                ],
              ),
            ),
          header(l.language),
          ListTile(
            key: const Key('language'),
            leading: const Icon(Icons.translate),
            title: Text(switch (ref.watch(languageSettingProvider)) {
              final code? => endonyms[code]!,
              null => l.languageSystem(endonyms[ref.watch(deviceLanguageProvider)]!),
            }),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickLanguage,
          ),
          header(l.appearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<ThemeMode>(
              key: const Key('appearance'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(l.appearanceSystem)),
                ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l.appearanceLight)),
                ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l.appearanceDark)),
              ],
              selected: {ref.watch(themeModeProvider)},
              onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.single),
            ),
          ),
          if (lockSupported) ...[
            header(l.security),
            SwitchListTile(
              key: const Key('app-lock'),
              secondary: const Icon(Icons.lock_outline),
              title: Text(l.appLock),
              subtitle: Text(k(l.appLockHint)),
              value: ref.watch(appLockProvider),
              onChanged: (on) => on
                  ? ref.read(appLockProvider.notifier).enable(l.lockReason)
                  : ref.read(appLockProvider.notifier).disable(),
            ),
          ],
          // The web app talks to the server that serves it, a release build to the one it was built for (docs/API.md,
          // Official server only).
          if (!kIsWeb && ref.watch(allowCustomServerProvider)) ...[
            header(l.server),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l.serverUrl,
                  helperText: l.serverDefault(Env.defaultServerUrl),
                  suffixIcon: IconButton(
                    tooltip: l.save,
                    icon: const Icon(Icons.save_outlined),
                    onPressed: () async {
                      await ref.read(serverUrlProvider.notifier).set(_url.text);
                      if (context.mounted) showInfo(context, context.l.serverSaved);
                    },
                  ),
                ),
              ),
            ),
          ],
          header(l.account),
          // Phase 10: hidden when this server sends no email.
          if (info.emailLogin)
            ListTile(
              key: const Key('account-email'),
              leading: Icon(session?.emailBounced == true ? Icons.warning_amber_rounded : Icons.mail_outline,
                  color: session?.emailBounced == true ? cs.error : null),
              title: Text(session?.email == null ? l.addEmail : l.emailLabel),
              subtitle: Text(
                  k(session?.email == null
                      ? l.addEmailHint
                      : session?.emailBounced == true
                          ? '${session!.email}\n${l.emailBouncedNote}'
                          : session!.email!),
                  style: session?.emailBounced == true ? TextStyle(color: cs.error) : null),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/email'),
            ),
          ListTile(
            key: const Key('blocked-people'),
            leading: const Icon(Icons.block),
            title: Text(l.blockedPeople),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/blocked'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l.signOut),
            onTap: _signOut,
          ),
          ListTile(
            key: const Key('sign-out-everywhere'),
            leading: const Icon(Icons.devices_other_outlined),
            title: Text(l.signOutEverywhere),
            onTap: _signOutEverywhere,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: cs.error),
            title: Text(l.deleteAccount, style: TextStyle(color: cs.error)),
            onTap: _deleteAccount,
          ),
          header(l.helpFeedback),
          ListTile(
            key: const Key('help-issue'),
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l.helpReportProblem),
            subtitle: Text(k(l.helpReportProblemHint)),
            onTap: () => _open(issuesUrl),
          ),
          if (info.supportEmail case final support?)
            ListTile(
              key: const Key('help-email'),
              leading: const Icon(Icons.mail_outline),
              title: Text(l.helpContact),
              subtitle: Text(support),
              onTap: () => openMail(context, support),
            ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.privacyPolicy),
            onTap: () => _open(privacyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.licenses),
            onTap: () => showLicensePage(context: context, applicationName: 'Evensies'),
          ),
        ],
      ),
    );
  }

  /// System (the phone's language) or one of the 13, each in its own name.
  Future<void> _pickLanguage() async {
    final current = ref.read(languageSettingProvider);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l.language),
        children: [
          RadioGroup<String>(
            groupValue: current ?? '',
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              RadioListTile<String>(
                  value: '', title: Text(ctx.l.languageSystem(endonyms[ref.read(deviceLanguageProvider)]!))),
              for (final MapEntry(key: code, value: name) in endonyms.entries)
                RadioListTile<String>(key: Key('language-$code'), value: code, title: Text(name)),
            ]),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(languageSettingProvider.notifier).set(picked.isEmpty ? null : picked);
  }

  Future<void> _signOut() async {
    final l = context.l;
    final ok = await confirm(context,
        title: l.signOutTitle, message: l.signOutMessage, confirmLabel: l.signOut, destructive: false);
    if (!ok) return;
    await ref.read(authServiceProvider).logout();
    if (mounted) context.go('/login');
  }

  /// Online only: the server has to drop the other devices' sign-ins.
  Future<void> _signOutEverywhere() async {
    final l = context.l;
    final ok = await confirm(context,
        title: l.signOutEverywhereTitle, message: l.signOutEverywhereMessage, confirmLabel: l.signOutEverywhere);
    if (!ok) return;
    try {
      await ref.read(authServiceProvider).logoutEverywhere();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) showError(context, e is ApiException && e.code == 'NETWORK' ? l.signOutEverywhereOffline : e);
    }
  }

  Future<void> _import(GroupRow g) async {
    try {
      final picked = (await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv'])).firstOrNull;
      if (picked == null) return;
      final r = await ref.read(apiProvider).importSplitwise(g.id, await picked.xFile.readAsBytes());
      ref.read(syncProvider).syncLater(g.id);
      if (mounted) showInfo(context, context.l.importedCount(r.imported));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _deleteAccount() async {
    final l = context.l;
    final ok = await confirm(context,
        title: l.deleteAccountTitle, message: [l.deleteAccountMessage, l.deleteAccountExportTip].join('\n\n'));
    if (!ok) return;
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}
