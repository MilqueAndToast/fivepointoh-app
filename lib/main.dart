import 'material_theme.dart';
import 'sheet_palette.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sheet_engine.dart';
import 'tabletop_widgets.dart';
import 'spell_card.dart';
import 'equipment_view.dart';
import 'attack_icons.dart';
import 'combat_view.dart';
import 'parchment_notes.dart';
import 'inline_text.dart';
import 'character_data.dart';
import 'appearance.dart';
import 'direct_editor.dart';
import 'category_colors.dart';
import 'health_adjustment.dart';

void main() => runApp(const LedgerApp());

class LedgerApp extends StatefulWidget {
  const LedgerApp({super.key});
  @override
  State<LedgerApp> createState() => _LedgerAppState();
}

class _LedgerAppState extends State<LedgerApp> {
  bool dark = true;
  SharedPreferences? preferences;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      if (mounted) {
        setState(() {
          preferences = value;
          dark = value.getBool('five-zero-dark-mode') ?? true;
        });
      }
    });
  }

  Future<void> toggleAppearance() async {
    final next = !dark;
    setState(() => dark = next);
    try {
      if (!await preferences!.setBool('five-zero-dark-mode', next)) {
        throw StateError('Preference was not saved.');
      }
    } catch (_) {
      if (mounted) setState(() => dark = !next);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => AppearanceScope(
    dark: dark,
    onToggle: preferences == null ? null : toggleAppearance,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '5.0 • Character Ledger',
      theme: ledgerMaterialTheme(desktop: false),
      darkTheme: ledgerMaterialTheme(desktop: false, dark: true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => Theme(
        data: ledgerMaterialTheme(
          desktop: MediaQuery.sizeOf(context).width >= 900,
          dark: dark,
        ),
        child: child!,
      ),
      home: const Ledger(),
    ),
  );
}

class Ledger extends StatefulWidget {
  const Ledger({super.key});
  @override
  State<Ledger> createState() => _LedgerState();
}

class _LedgerState extends State<Ledger> {
  Map<String, dynamic>? source, user, record;
  Map<String, dynamic> overrides = {};
  List<dynamic> roster = [], people = [], history = [];
  String? token;
  String page = 'Overview', search = '', status = '';
  final Set<String> expandedSpells = {};
  final Set<String> collapsedAbilities = {};
  bool resourcesExpanded = true, conditionsExpanded = true;
  static const abilityGroups = [
    ('Class', 'D', 'M', 'B', 6, 35),
    ('Trade', 'D', 'M', 'B', 41, 56),
    ('Feats', 'AL', 'AU', 'AJ', 6, 35),
    ('Ancestry', 'AL', 'AU', 'AT', 41, 62),
  ];
  Set<String> get abilityIds => {
    for (final group in abilityGroups)
      for (var r = group.$5; r <= group.$6; r++)
        if (v('${group.$2}$r', 'Abilities').isNotEmpty)
          'Abilities!${group.$2}$r',
    for (final entry in appEntries('ability')) entry.$1,
  };
  Set<String> get spellIds => {
    for (final column in [
      'G',
      'N',
      'U',
      'AB',
      'AI',
      'AP',
      'AW',
      'BD',
      'BK',
      'BR',
    ])
      for (var row = 44; row <= 52; row++)
        if (v('$column$row').isNotEmpty) '$column$row',
    for (final entry in appEntries('spell')) entry.$1,
  };
  final Set<String> inlineDrafts = {};
  Set<String>? calculationReferences;
  bool calculationLinked(String sheet, String address) =>
      rules.cell(sheet, address)['userEnteredValue']?['formulaValue'] != null ||
      (calculationReferences ??= rules.calculationInputs).contains(
        '$sheet!$address',
      );
  bool loading = true, editing = false, saving = false, local = false;
  Timer? timer;
  late SharedPreferences prefs;
  SheetEngine get rules => SheetEngine(source!['sheets'], overrides);
  String v(String a, [String sh = 'Main']) => rules.display(sh, a);
  dynamic raw(String a, [String sh = 'Main']) => rules.value(sh, a);
  bool get isDm => user?['role'] == 'dm';
  static const pages = [
    'Overview',
    'Abilities',
    'Spellbook',
    'Inventory',
    'Workshop',
    'Activity',
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.auto_awesome_outlined,
    Icons.menu_book_outlined,
    Icons.backpack_outlined,
    Icons.tune,
    Icons.history,
  ];
  String get apiBase {
    const defined = String.fromEnvironment('API_BASE');
    return defined.isEmpty
        ? (kIsWeb ? Uri.base.origin : 'http://10.0.2.2:8080')
        : defined;
  }

  @override
  void initState() {
    super.initState();
    initialize();
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (token != null && !editing && inlineDrafts.isEmpty && !saving) {
        refresh(silent: true);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    source = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/reference.json')),
    );
    prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => loading = false);
  }

  Future<dynamic> api(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(method, Uri.parse('$apiBase/api/$path'));
    request.headers.addAll({
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    });
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 20)),
    );
    dynamic result;
    try {
      result = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'The campaign server is unavailable. Start it using start.ps1.',
      );
    }
    if (response.statusCode >= 400) {
      throw Exception(result['error'] ?? 'Request failed.');
    }
    return result;
  }

  void notify(Object message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: DiceText(message.toString().replaceFirst('Exception: ', '')),
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }

  Future<void> login(String username, String password) async {
    final result = await api('POST', 'login', {
      'username': username,
      'password': password,
    });
    token = result['token'];
    user = Map<String, dynamic>.from(result['user']);
    local = false;
    await refresh();
  }

  Future<void> explore() async {
    final stored = prefs.getString('five-zero-local-values');
    overrides = stored == null
        ? {}
        : Map<String, dynamic>.from(jsonDecode(stored));
    final h = prefs.getString('five-zero-local-history');
    history = h == null ? [] : jsonDecode(h);
    setState(() {
      local = true;
      record = {'name': v('B2'), 'revision': 0, 'owner': 'This device'};
      status = 'Saved on this device';
    });
  }

  Future<void> refresh({bool silent = false, String? selectId}) async {
    try {
      final list = await api('GET', 'characters') as List;
      final usersList = isDm ? await api('GET', 'users') as List : <dynamic>[];
      final id =
          selectId ?? record?['id'] ?? (list.isEmpty ? null : list.first['id']);
      Map<String, dynamic>? next;
      List<dynamic> logs = [];
      if (id != null) {
        next = Map<String, dynamic>.from(await api('GET', 'characters/$id'));
        next['id'] = id;
        logs = await api('GET', 'characters/$id/history');
      }
      if (!mounted) return;
      setState(() {
        roster = list;
        people = usersList;
        record = next;
        overrides = Map<String, dynamic>.from(next?['overrides'] ?? {});
        history = logs;
        status = 'Up to date • checked ${TimeOfDay.now().format(context)}';
      });
    } catch (e) {
      if (mounted) {
        setState(() => status = 'Connection lost • edits need the server');
      }
      if (!silent) rethrow;
    }
  }

  Future<void>? _pendingCommit;
  Future<void> commit(Map<String, dynamic> changes) {
    final previous = _pendingCommit;
    final next = previous == null
        ? _commit(changes)
        : previous.then(
            (_) => _commit(changes),
            onError: (Object _, StackTrace _) => _commit(changes),
          );
    _pendingCommit = next;
    void clear() {
      if (identical(_pendingCommit, next)) _pendingCommit = null;
    }

    next.then((_) => clear(), onError: (Object _, StackTrace _) => clear());
    return next;
  }

  Future<void> _commit(Map<String, dynamic> changes) async {
    for (final entry in changes.entries) {
      if (entry.key.startsWith('App!')) {
        validateAppField(entry.key, entry.value);
      } else {
        final parts = entry.key.split('!');
        if (parts.length != 2 ||
            rules.cell(
                  parts[0],
                  parts[1],
                )['userEnteredValue']?['formulaValue'] !=
                null) {
          throw const FormatException(
            'Calculated fields cannot be overwritten.',
          );
        }
      }
    }
    saving = true;
    try {
      final candidate = {...overrides, ...changes},
          engine = SheetEngine(source!['sheets'], candidate);
      for (final sh in (source!['sheets'] as Map).entries) {
        for (final a in (sh.value as Map).keys) {
          engine.value(sh.key, a);
        }
      }
      if (local) {
        final nextHistory = [
          {
            'actor': 'Local player',
            'at': DateTime.now().toUtc().toIso8601String(),
            'action': 'edited',
            'changes': changes,
          },
          ...history,
        ].take(100).toList();
        await prefs.setString('five-zero-local-values', jsonEncode(candidate));
        await prefs.setString(
          'five-zero-local-history',
          jsonEncode(nextHistory),
        );
        setState(() {
          overrides = candidate;
          history = nextHistory;
          status = 'Saved on this device';
        });
      } else {
        await api('PATCH', 'characters/${record!['id']}', {
          'revision': record!['revision'],
          'changes': changes,
        });
        await refresh();
      }
    } finally {
      saving = false;
    }
  }

  Future<void> editFields(String title, Map<String, String> fields) async {
    if (editing) return;
    editing = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => EditDialog(
          title: title,
          fields: fields,
          engine: rules,
          onSave: commit,
        ),
      );
    } finally {
      editing = false;
    }
    if (mounted) setState(() {});
  }

  Widget textLabel(String text, {Color? color}) => DiceText(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      letterSpacing: .9,
      color: color ?? SheetPalette.of(context).muted,
      fontWeight: FontWeight.w600,
    ),
  );
  Widget heading(String title, {String? sub, VoidCallback? edit}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiceText(title, style: Theme.of(context).textTheme.titleLarge),
              if (sub != null)
                DiceText(
                  sub,
                  style: TextStyle(
                    color: SheetPalette.of(context).muted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (edit != null)
          IconButton(
            onPressed: edit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: titleCaseLabel('Edit $title'),
          ),
      ],
    ),
  );
  Widget box(Widget child, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: SheetPalette.of(context).border, width: .8),
      ),
    ),
    child: child,
  );
  Widget stat(
    String label,
    String value, {
    String? hint,
    VoidCallback? onTap,
    bool uniform = false,
    bool blankWhenEmpty = false,
    Color? ink,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.zero,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: SheetPalette.of(context).border.withValues(alpha: .65),
            width: .6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: uniform ? 24 : 14,
            child: Text(
              label.toUpperCase(),
              maxLines: uniform ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                letterSpacing: .6,
                fontWeight: FontWeight.w600,
                color: ink ?? SheetPalette.of(context).cutout,
              ),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: DiceText(
              value.isEmpty && !blankWhenEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 23,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: ink ?? sheetValueColor(value, SheetPalette.of(context)),
              ),
            ),
          ),
          if (hint != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: DiceText(
                hint,
                style: TextStyle(
                  color: ink ?? SheetPalette.of(context).cutout,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    ),
  );
  Widget line(String label, String value, {VoidCallback? edit, String? note}) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: DiceText(titleCaseLabel(label)),
        subtitle: note == null
            ? null
            : DiceText(
                note,
                style: TextStyle(
                  color: SheetPalette.of(context).muted,
                  fontSize: 12,
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DiceText(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: sheetValueColor(value, SheetPalette.of(context)),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (edit != null)
              IconButton(
                onPressed: edit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                tooltip: titleCaseLabel('Edit $label'),
              ),
          ],
        ),
      );
  String signed(String s) =>
      num.tryParse(s) != null && num.parse(s) >= 0 ? '+$s' : s;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!local && token == null) {
      return LoginScreen(onLogin: login, onExplore: explore);
    }
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final navigation = [...pages, if (isDm) 'DM desk'];
    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: const DiceText(
                '5.0 / Character Ledger',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                const AppearanceToggle(compact: true),
                IconButton(
                  onPressed: logout,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                ),
              ],
            ),
      drawer: wide
          ? null
          : Drawer(child: SafeArea(child: navigationList(navigation, true))),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Material(
                color: SheetPalette.of(context).deep,
                child: Container(
                  width: 190,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: SheetPalette.of(context).border,
                        width: .6,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: navigationList(navigation, false),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: SheetPalette.of(
                            context,
                          ).border.withValues(alpha: .6),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          local ? Icons.laptop : Icons.cloud_done_outlined,
                          size: 16,
                          color: SheetPalette.of(context).muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DiceText(
                            local
                                ? 'LOCAL EXPLORATION • not shared with your DM'
                                : status,
                            style: TextStyle(
                              fontSize: 12,
                              color: SheetPalette.of(context).muted,
                            ),
                          ),
                        ),
                        if (!local)
                          IconButton(
                            onPressed: () async {
                              try {
                                await refresh();
                              } catch (e) {
                                notify(e);
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            tooltip: 'Refresh Character',
                          ),
                        if (wide) const AppearanceToggle(),
                        if (local)
                          TextButton(
                            onPressed: () => copyBackup(),
                            child: const DiceText('Copy Backup'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: record == null
                        ? Center(
                            child: DiceText(
                              isDm
                                  ? 'Create a character from the DM desk.'
                                  : 'Your DM has not assigned a character yet.',
                            ),
                          )
                        : SingleChildScrollView(
                            key: ValueKey(page),
                            padding: EdgeInsets.all(wide ? 20 : 14),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1680,
                                ),
                                child: Column(
                                  key: ValueKey(
                                    record?['id'] ?? 'local-character',
                                  ),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    characterHeader(),
                                    const SizedBox(height: 16),
                                    switch (page) {
                                      'Overview' => overview(),
                                      'Abilities' => abilities(),
                                      'Spellbook' => spellbook(),
                                      'Inventory' => inventory(),
                                      'Workshop' => workshop(),
                                      'Activity' => activity(),
                                      _ => dmDesk(),
                                    },
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget navigationList(List<String> navigation, bool drawer) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      DiceText(
        '5.0',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: SheetPalette.of(context).accent,
        ),
      ),
      textLabel('Character Ledger'),
      const SizedBox(height: 12),
      Expanded(
        child: ListView(
          children: [
            for (final entry in navigation.asMap().entries)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: page == entry.value
                          ? SheetPalette.of(context).accent
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10, right: 4),
                  leading: Icon(
                    entry.key < icons.length
                        ? icons[entry.key]
                        : Icons.groups_outlined,
                    size: 19,
                    color: page == entry.value
                        ? SheetPalette.of(context).accent
                        : SheetPalette.of(context).text,
                  ),
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: page == entry.value
                          ? SheetPalette.of(context).accent
                          : SheetPalette.of(context).text,
                      fontWeight: page == entry.value
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      page = entry.value;
                      search = '';
                    });
                    if (drawer) Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ),
      if (!local && roster.isNotEmpty)
        DropdownButtonFormField<String>(
          initialValue: record?['id'],
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Character'),
          items: roster
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c['id'],
                  child: DiceText(c['name'], overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (id) async {
            try {
              await refresh(selectId: id);
            } catch (e) {
              notify(e);
            }
          },
        ),
      const SizedBox(height: 12),
      DiceText(
        local
            ? 'Local reference'
            : '${user?['username']} • ${isDm ? 'Dungeon Master' : 'Player'}',
        style: TextStyle(color: SheetPalette.of(context).muted, fontSize: 12),
      ),
      TextButton.icon(
        onPressed: logout,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        icon: const Icon(Icons.logout, size: 16),
        label: DiceText(
          local ? 'Back To Sign In' : 'Sign Out',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      const SizedBox(height: 14),
    ],
  );
  Future<void> logout() async {
    if (token != null) {
      try {
        await api('POST', 'logout');
      } catch (_) {}
    }
    setState(() {
      token = null;
      user = null;
      record = null;
      local = false;
      overrides = {};
      page = 'Overview';
    });
  }

  Widget characterHeader() => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 24,
    runSpacing: 14,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textLabel('$page / Level ${v('B4', 'Stats')}'),
          const SizedBox(height: 5),
          DiceText(v('B2'), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          DiceText(
            '${v('B6')}  /  ${v('I6')}  /  ${v('P6')}',
            style: TextStyle(color: SheetPalette.of(context).muted),
          ),
        ],
      ),
      OutlinedButton.icon(
        onPressed: () => editFields('Character identity', {
          'Main!B2': 'Character name',
          'Main!B6': 'Ancestry',
          'Main!I6': 'Class',
          'Main!P6': 'Trade',
          'Main!W6': 'Curse',
          'Stats!B4': 'Level',
          'Stats!G4': 'Size (T / S / M / L / H / G)',
          'Stats!K4': 'Defense mode (Block / Dodge)',
        }),
        icon: const Icon(Icons.edit_outlined, size: 17),
        label: const DiceText('Edit Character'),
      ),
    ],
  );
  Widget overview() => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth > 850;
      final primary = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          health(),
          const SizedBox(height: 12),
          defenses(),
          const SizedBox(height: 12),
          attacks(),
          const SizedBox(height: 12),
          abilityScores(),
        ],
      );
      final secondary = Column(
        children: [
          resources(),
          const SizedBox(height: 12),
          conditions(),
          const SizedBox(height: 12),
          skills(),
          const SizedBox(height: 12),
          notes(),
        ],
      );
      return wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: primary),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.only(left: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: SheetPalette.of(context).border,
                          width: .6,
                        ),
                      ),
                    ),
                    child: secondary,
                  ),
                ),
              ],
            )
          : Column(children: [primary, const SizedBox(height: 12), secondary]);
    },
  );
  Widget health() {
    final maxHp = SheetEngine.number(raw('Q4', 'Stats')),
        damage = SheetEngine.number(raw('AU4')),
        current = maxHp - damage;
    return box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textLabel('Vitality', color: SheetPalette.of(context).text),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            children: [
              DiceText(
                '$current'.replaceAll('.0', ''),
                style: TextStyle(
                  fontSize: 64,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                  color: sheetValueColor('$current', SheetPalette.of(context)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DiceText(
                  '/ ${SheetEngine.text(maxHp)} HP',
                  style: TextStyle(
                    fontSize: 20,
                    color: SheetPalette.of(context).text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: maxHp == 0 ? 0 : (current / maxHp).clamp(0, 1).toDouble(),
              minHeight: 8,
              color: SheetPalette.of(context).aqua,
              backgroundColor: SheetPalette.of(
                context,
              ).border.withValues(alpha: .3),
            ),
          ),
          const SizedBox(height: 10),
          DiceText(
            current > maxHp
                ? '${SheetEngine.text(current - maxHp)} above maximum • damage field is ${v('AU4')}'
                : 'Damage taken: ${v('AU4')}  •  ${v('AU3')}',
            style: TextStyle(
              color: SheetPalette.of(context).muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonStyle = ButtonStyle(
                fixedSize: WidgetStatePropertyAll(
                  Size(constraints.maxWidth.clamp(0, 220).toDouble(), 44),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                visualDensity: VisualDensity.standard,
              );
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: constraints.maxWidth.clamp(0, 220).toDouble(),
                    child: HealthAdjustment(
                      onApply: (amount) => commit({
                        'Main!AU4': SheetEngine.number(raw('AU4')) + amount,
                      }),
                      onEditingChanged: (value) => markDraft('health', value),
                    ),
                  ),
                  OutlinedButton(
                    key: const ValueKey('hit-dice'),
                    style: buttonStyle.copyWith(
                      foregroundColor: WidgetStatePropertyAll(
                        SheetPalette.of(context).accent,
                      ),
                    ),
                    onPressed: () => editFields('Hit Dice', {
                      'Main!AZ4': 'Hit dice remaining',
                      'Stats!V4': 'Healthy feat',
                    }),
                    child: DiceText(
                      'Hit Dice ${v('AZ4')}${v('BB4')} • ${v('AZ3')}',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      color: SheetPalette.of(context).vitality,
    );
  }

  Widget openStats(List<Widget> children, {double minWidth = 100}) =>
      LayoutBuilder(
        builder: (context, c) {
          final columns = (c.maxWidth / minWidth).floor().clamp(2, 7);
          return Wrap(
            runSpacing: 16,
            children: [
              for (final child in children)
                SizedBox(width: c.maxWidth / columns, height: 84, child: child),
            ],
          );
        },
      );
  Widget defenses() => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Defenses & Movement',
          sub: 'Calculated from your stats and active conditions',
        ),
        openStats([
          for (final entry in {
            'Block & Dodge': 'BB9',
            'Touch': 'BB11',
            'Surprised': 'BB13',
            'CMD': 'BB15',
            'Fortitude': 'AS11',
            'Reflex': 'AS13',
            'Will': 'AS15',
            'Initiative': 'AS9',
          }.entries)
            stat(entry.key, v(entry.value), uniform: true),
          for (final entry in {
            'Ground': 'AS17',
            'Swim': 'AS19',
            'Burrow': 'AS21',
            'Climb': 'BB17',
            'Fly': 'BB21',
            'Crawl': 'BB19',
          }.entries)
            stat(
              entry.key,
              v(entry.value).trim().toUpperCase() == 'N/A'
                  ? ''
                  : '${v(entry.value)} ft',
              uniform: true,
              blankWhenEmpty: true,
            ),
        ]),
      ],
    ),
  );
  Future<void> resourceChange(String address, dynamic value) async {
    try {
      await commit({'Main!$address': value});
    } catch (e) {
      notify(e);
    }
  }

  Widget resourceRow(String label, Widget control) => Row(
    children: [
      Expanded(child: DiceText(label)),
      control,
    ],
  );
  Widget resourceChoice(String address, String label, List<int> options) =>
      DropdownButton<int>(
        key: ValueKey('resource-$address'),
        value: num.tryParse(v(address))?.toInt() ?? 0,
        underline: const SizedBox.shrink(),
        onChanged: (value) {
          if (value != null) resourceChange(address, value);
        },
        items: options
            .map(
              (value) => DropdownMenuItem(value: value, child: Text('$value')),
            )
            .toList(),
      );
  Widget collapsibleSection({
    required String title,
    required String id,
    required bool expanded,
    required VoidCallback toggle,
    required List<Widget> children,
  }) => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: '${expanded ? 'Collapse' : 'Expand'} $title',
          child: Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              key: ValueKey('toggle-$id'),
              onTap: () {
                FocusScope.of(context).unfocus();
                toggle();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Expanded(
                      child: DiceText(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Keep inline drafts and control state when the section is folded.
        Offstage(
          offstage: !expanded,
          child: ExcludeFocus(
            excluding: !expanded,
            child: TickerMode(
              enabled: expanded,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget resources() => collapsibleSection(
    title: 'Turn resources',
    id: 'resources',
    expanded: resourcesExpanded,
    toggle: () => setState(() => resourcesExpanded = !resourcesExpanded),
    children: [
      DirectEditor(
        key: ValueKey('resources-${record?['id'] ?? 'local'}'),
        name: 'Resources',
        values: {'Main!AR25': raw('AR25')},
        integers: const {'Main!AR25'},
        onEditingChanged: (value) => markDraft('resources', value),
        onSave: commit,
        builder: (context, draft) => resourceRow(
          'Reactions',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 58,
                child: draft.field(
                  'Main!AR25',
                  'Reactions remaining',
                  align: TextAlign.end,
                ),
              ),
              DiceText(v('AT25')),
            ],
          ),
        ),
      ),
      resourceRow(
        'Shield bonus lost',
        Semantics(
          label: 'Shield bonus lost',
          child: resourceChoice('AW25', 'Shield bonus lost', [
            0,
            2,
            3,
            4,
            6,
            8,
          ]),
        ),
      ),
      Wrap(
        spacing: 7,
        runSpacing: 6,
        children: [
          for (final (address, name) in [
            ('BB25', 'Shield I'),
            ('BD25', 'Shield II'),
          ])
            FilterChip(
              key: ValueKey('resource-$address'),
              label: Text(
                '$name ${raw(address) == true ? 'Equipped' : 'Away'}',
              ),
              selected: raw(address) == true,
              onSelected: (value) => resourceChange(address, value),
            ),
        ],
      ),
      resourceRow(
        'Strong Ideals',
        Semantics(
          toggled: raw('BG25') == true,
          child: TextButton.icon(
            key: const ValueKey('resource-BG25'),
            onPressed: () => resourceChange('BG25', raw('BG25') != true),
            icon: Icon(
              raw('BG25') == true
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank,
              size: 18,
            ),
            label: Text(raw('BG25') == true ? 'Active' : 'Inactive'),
          ),
        ),
      ),
      resourceRow(
        'Allies ahead in initiative',
        Semantics(
          label: 'Allies ahead in initiative',
          child: resourceChoice('BJ25', 'Allies ahead in initiative', [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
          ]),
        ),
      ),
      const SizedBox(height: 6),
      textLabel('Hero points'),
      Wrap(
        children: [
          for (final (i, address) in ['AN25', 'AO25', 'AP25'].indexed)
            IconButton(
              key: ValueKey('resource-$address'),
              onPressed: () => resourceChange(address, raw(address) != true),
              tooltip: 'Toggle Hero Point ${i + 1}',
              icon: Icon(
                raw(address) == true ? Icons.stars : Icons.star_border,
                color: SheetPalette.of(context).accent,
              ),
            ),
        ],
      ),
      DiceText(
        'Resources change only when you edit them; actions are not spent automatically.',
        style: TextStyle(color: SheetPalette.of(context).muted, fontSize: 11),
      ),
    ],
  );
  Widget conditions() => collapsibleSection(
    title: 'Conditions',
    id: 'conditions',
    expanded: conditionsExpanded,
    toggle: () => setState(() => conditionsExpanded = !conditionsExpanded),
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DiceText(
          'Toggle to recalculate affected values',
          style: TextStyle(color: SheetPalette.of(context).muted, fontSize: 12),
        ),
      ),
      LayoutBuilder(
        builder: (context, c) {
          final columns = c.maxWidth >= 360 ? 3 : 2;
          return Wrap(
            children: [
              for (var r = 5; r <= 19; r++)
                if (v('BG$r').isNotEmpty)
                  SizedBox(
                    width: c.maxWidth / columns,
                    child: Tooltip(
                      message:
                          rules.cell('Main', 'BG$r')['note'] ??
                          'No description in source',
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          v('BG$r'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: raw('BF$r') == true,
                        onChanged: (value) async {
                          try {
                            await commit({'Main!BF$r': value == true});
                          } catch (error) {
                            notify(error);
                          }
                        },
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
      const SizedBox(height: 14),
      DiceText(
        'Narrative effects, disadvantage, and action restrictions are shown in tooltips. Only sheet formulas change numeric totals.',
        style: TextStyle(color: SheetPalette.of(context).muted, fontSize: 11),
      ),
    ],
  );
  Widget attacks() => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Attacks',
          sub: 'Select an attack to view its rolls and damage',
        ),
        CombatView(
          attacks: [
            for (var r = 29; r <= 34; r++)
              if (v('AP$r').trim().isNotEmpty)
                AttackEntry(
                  row: r,
                  name: v('AP$r'),
                  variety: v('BZ$r', 'Misc').isEmpty
                      ? defaultAttackVariety(v('AP$r'))
                      : v('BZ$r', 'Misc'),
                  damageType: v('BD$r'),
                  damage: v('AY$r'),
                  range: v('BF$r'),
                  critical: v('BG$r'),
                  ammo: v('BI$r'),
                  rolls: [
                    for (final a in ['AV', 'AW', 'AX']) v('$a$r'),
                  ],
                ),
          ],
          onEdit: (r) => editFields('Edit ${v('AP$r')}', {
            'Main!AP$r': 'Name',
            'Main!AU$r': 'Attack Calculation',
            'Main!BC$r': 'Base Damage Dice',
            'Main!BF$r': 'Range / Reach (ft)',
            'Main!BG$r': 'Critical',
            'Main!BI$r': 'Ammo',
            if (r > 31) 'Main!AN$r': 'Attack Bonus',
            if (r > 31) 'Main!AO$r': 'Damage Bonus',
          }),
          // Misc!BZ29:BZ34 stores app icon choices alongside the character's overrides.
          onAssign: (r, value, damage) =>
              commit({damage ? 'Main!BD$r' : 'Misc!BZ$r': value}),
        ),
      ],
    ),
  );
  Widget abilityScores() => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Ability scores', sub: 'Tap a score to edit its inputs'),
        openStats([
          for (final r in [12, 14, 16, 18, 20, 22, 24])
            stat(
              v('R$r'),
              signed(v('U$r')),
              hint: 'Score ${v('X$r')}',
              ink: abilityCategoryColor(v('R$r'), SheetPalette.of(context)),
              onTap: () => r == 24
                  ? editFields('Luck', {
                      'Main!X24': 'Luck score',
                      'Main!AA24': 'Luck temporary modifier',
                    })
                  : editAbility(r),
            ),
        ]),
      ],
    ),
  );
  Future<void> editAbility(int mainRow) {
    final sr = {12: 10, 14: 13, 16: 16, 18: 19, 20: 22, 22: 25}[mainRow]!,
        br = {12: 42, 14: 44, 16: 46, 18: 48, 20: 50, 22: 52}[mainRow]!;
    return editFields(v('R$mainRow'), {
      'Stats!F$br': 'Ancestry +2',
      'Stats!H$br': 'Flaw −2',
      'Stats!J$br': 'Trade +2',
      'Stats!L$br': 'Class +2',
      'Stats!N$br': 'Level 1 +2',
      'Stats!P$br': 'Other base modifier',
      'Stats!H$sr': 'Magic bonus',
      'Main!AA$mainRow': 'Temporary modifier',
    });
  }

  Widget skills() => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Skills',
          sub: 'Ranks ${v('BL54', 'Stats')} / ${v('BO54', 'Stats')}',
        ),
        DirectEditor(
          key: ValueKey('skill-ranks-${record?['id'] ?? 'local'}'),
          name: 'Ranks',
          values: {
            for (var r = 5; r <= 27; r++)
              if (v('AE$r').isNotEmpty)
                'Stats!BL${8 + 2 * (r - 5)}': raw(
                  'BL${8 + 2 * (r - 5)}',
                  'Stats',
                ),
          },
          integers: {
            for (var r = 5; r <= 27; r++) 'Stats!BL${8 + 2 * (r - 5)}',
          },
          onEditingChanged: (value) => markDraft('skill-ranks', value),
          onSave: commit,
          builder: (context, draft) => Column(
            children: [
              Row(
                children: [
                  Expanded(child: textLabel('Skill')),
                  SizedBox(width: 64, child: Center(child: textLabel('Ranks'))),
                  SizedBox(width: 58, child: Center(child: textLabel('Total'))),
                  const SizedBox(width: 44),
                ],
              ),
              for (var r = 5; r <= 27; r++)
                if (v('AE$r').isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: DiceText(
                          v('AE$r'),
                          style: TextStyle(
                            color: abilityCategoryColor(
                              v('BC${8 + 2 * (r - 5)}', 'Stats'),
                              SheetPalette.of(context),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: draft.field(
                          'Stats!BL${8 + 2 * (r - 5)}',
                          '${v('AE$r')} ranks',
                          align: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: abilityCategoryColor(
                              v('BC${8 + 2 * (r - 5)}', 'Stats'),
                              SheetPalette.of(context),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 58,
                        child: Center(
                          child: DiceText(
                            signed(v('AK$r')),
                            style: TextStyle(
                              color: abilityCategoryColor(
                                v('BC${8 + 2 * (r - 5)}', 'Stats'),
                                SheetPalette.of(context),
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: IconButton(
                          tooltip: 'Edit ${v('AE$r')} Miscellaneous Bonus',
                          onPressed: () =>
                              editFields('${v('AE$r')} miscellaneous bonus', {
                                'Stats!BO${8 + 2 * (r - 5)}':
                                    'Miscellaneous bonus',
                              }),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: abilityCategoryColor(
                              v('BC${8 + 2 * (r - 5)}', 'Stats'),
                              SheetPalette.of(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget notes() => ParchmentNotes(
    key: ValueKey('notes-${record?['id'] ?? 'local'}'),
    text: [
      for (var r = 25; r <= 36; r++)
        if (v('B$r').isNotEmpty) v('B$r'),
    ].join('\n'),
    onEditingChanged: (value) => markDraft('quick-notes', value),
    onSave: (text) => commit({
      'Main!B25': text,
      for (var r = 26; r <= 36; r++) 'Main!B$r': null,
    }),
  );
  void markDraft(String id, bool value) {
    if (value) {
      inlineDrafts.add(id);
    } else {
      inlineDrafts.remove(id);
    }
  }

  List<(String, Map<String, dynamic>)> appEntries(String kind) => [
    for (final entry in overrides.entries)
      if (entry.key.startsWith('App!entry_') &&
          entry.value is Map &&
          entry.value['kind'] == kind)
        (entry.key, Map<String, dynamic>.from(entry.value)),
  ];
  Widget inlineField(
    String sheet,
    String address,
    String label, {
    String? text,
    String? display,
  }) {
    final value = text ?? v(address, sheet);
    if (calculationLinked(sheet, address)) {
      return DiceText(display ?? value);
    }
    final id = '$sheet!$address';
    return InlineText(
      key: ValueKey('inline-$id'),
      text: value,
      displayText: display,
      label: label,
      onEditingChanged: (value) => markDraft(id, value),
      onSave: (text) => commit({id: text}),
    );
  }

  Widget customDescription(
    String key,
    Map<String, dynamic> entry, {
    String? display,
  }) => InlineText(
    key: ValueKey('inline-$key'),
    text: entry['description'],
    displayText: display,
    label: 'Description',
    onEditingChanged: (value) => markDraft(key, value),
    onSave: (text) => commit({
      key: {...entry, 'description': text},
    }),
  );
  Future<void> removeEntry(Map<String, dynamic> changes, String name) async {
    final before = {
      for (final key in changes.keys)
        key: overrides.containsKey(key)
            ? overrides[key]
            : SheetEngine(
                source!['sheets'],
              ).value(key.split('!').first, key.split('!').last),
    };
    try {
      await commit(changes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await commit(before);
              } catch (error) {
                notify(error);
              }
            },
          ),
        ),
      );
    } catch (error) {
      notify(error);
    }
  }

  Future<void> finishDialog(WidgetBuilder builder) async {
    final route = DialogRoute<void>(context: context, builder: builder);
    await Navigator.of(context).push(route);
    await route.completed;
  }

  Future<void> addEntry(
    String kind, {
    String? group,
    int? level,
    String? entryKey,
    Map<String, dynamic>? existing,
  }) async {
    final name = TextEditingController(text: existing?['name'] ?? ''),
        description = TextEditingController(
          text: existing?['description'] ?? '',
        );
    bool busy = false;
    String? error;
    editing = true;
    try {
      await finishDialog(
        (ctx) => StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            title: Text(
              '${existing == null ? 'Add' : 'Edit'} ${kind == 'spell' ? 'Spell' : 'Ability'}',
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kind == 'spell'
                          ? (level == 0 ? 'Cantrip' : 'Level $level')
                          : group!,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('new-entry-name'),
                      controller: name,
                      maxLength: 160,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('new-entry-description'),
                      controller: description,
                      minLines: 4,
                      maxLines: 9,
                      maxLength: 12000,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: SheetPalette.of(context).accent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        set(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          final key =
                              entryKey ??
                              'App!entry_${DateTime.now().microsecondsSinceEpoch}';
                          await commit({
                            key: {
                              'kind': kind,
                              'name': name.text.trim(),
                              'description': description.text,
                              if (kind == 'spell')
                                'level': level
                              else
                                'group': group,
                            },
                          });
                          if (kind == 'spell') expandedSpells.add(key);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          set(() {
                            busy = false;
                            error = '$e';
                          });
                        }
                      },
                child: Text(
                  busy
                      ? 'Saving…'
                      : existing == null
                      ? 'Add'
                      : 'Save',
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      editing = false;
      name.dispose();
      description.dispose();
    }
  }

  Widget removeButton(String name, Map<String, dynamic> changes) => IconButton(
    tooltip: 'Remove $name',
    icon: const Icon(Icons.delete_outline, size: 18),
    onPressed: () => removeEntry(changes, name),
  );
  void toggleAbility(String id) {
    if (!collapsedAbilities.contains(id)) FocusScope.of(context).unfocus();
    setState(() {
      if (!collapsedAbilities.add(id)) collapsedAbilities.remove(id);
    });
  }

  Widget abilityDescription(String id, Widget child) => Offstage(
    offstage: collapsedAbilities.contains(id),
    child: ExcludeFocus(
      excluding: collapsedAbilities.contains(id),
      child: child,
    ),
  );

  Widget abilityHeading(
    String title, {
    required String id,
    String? level,
    required VoidCallback edit,
    Widget? remove,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            expanded: !collapsedAbilities.contains(id),
            child: InkWell(
              onTap: () => toggleAbility(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    DiceText(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (level != null && level.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: SheetPalette.of(context).border,
                              width: .7,
                            ),
                          ),
                        ),
                        child: Text(
                          'Level $level',
                          style: TextStyle(
                            fontSize: 12,
                            color: SheetPalette.of(context).muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: edit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: titleCaseLabel('Edit $title'),
        ),
        ?remove,
        IconButton(
          key: ValueKey('toggle-ability-$id'),
          tooltip:
              '${collapsedAbilities.contains(id) ? 'Expand' : 'Collapse'} $title',
          onPressed: () => toggleAbility(id),
          icon: Icon(
            collapsedAbilities.contains(id)
                ? Icons.expand_more
                : Icons.expand_less,
            size: 20,
          ),
        ),
      ],
    ),
  );
  Widget abilities() {
    const sh = 'Abilities';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Abilities & Features',
          sub: 'Class, trade, ancestry, and feats at a glance',
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            key: const ValueKey('toggle-all-abilities'),
            onPressed: abilityIds.isEmpty
                ? null
                : () {
                    final ids = abilityIds;
                    final expand = ids.every(collapsedAbilities.contains);
                    if (!expand) FocusScope.of(context).unfocus();
                    setState(() {
                      if (expand) {
                        collapsedAbilities.removeAll(ids);
                      } else {
                        collapsedAbilities.addAll(ids);
                      }
                    });
                  },
            icon: Icon(
              abilityIds.every(collapsedAbilities.contains)
                  ? Icons.unfold_more
                  : Icons.unfold_less,
            ),
            label: Text(
              abilityIds.every(collapsedAbilities.contains)
                  ? 'Expand All'
                  : 'Collapse All',
            ),
          ),
        ),
        const SizedBox(height: 12),
        searchBox(),
        const SizedBox(height: 12),
        for (final group in abilityGroups) ...[
          Container(
            margin: EdgeInsets.only(
              top: group.$1 == 'Class' ? 16 : 40,
              bottom: 10,
            ),
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: SheetPalette.of(context).border,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      group.$1.toUpperCase(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: SheetPalette.of(context).accent,
                      ),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => addEntry('ability', group: group.$1),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Ability'),
                ),
              ],
            ),
          ),
          for (var r = group.$5; r <= group.$6; r++)
            if (v('${group.$2}$r', sh).isNotEmpty &&
                matches('${v('${group.$2}$r', sh)} ${v('${group.$3}$r', sh)}'))
              box(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    abilityHeading(
                      v('${group.$2}$r', sh),
                      id: '$sh!${group.$2}$r',
                      level: v('${group.$4}$r', sh),
                      edit: () => editFields('Edit Feature', {
                        '$sh!${group.$2}$r': 'Name',
                        '$sh!${group.$3}$r': 'Description',
                        '$sh!${group.$4}$r': 'Level',
                      }),
                      remove:
                          !calculationLinked(sh, '${group.$2}$r') &&
                              !calculationLinked(sh, '${group.$3}$r')
                          ? removeButton(v('${group.$2}$r', sh), {
                              '$sh!${group.$2}$r': '',
                              '$sh!${group.$3}$r': '',
                            })
                          : null,
                    ),
                    abilityDescription(
                      '$sh!${group.$2}$r',
                      inlineField(sh, '${group.$3}$r', 'Description'),
                    ),
                  ],
                ),
              ),
          for (final entry in appEntries('ability'))
            if (entry.$2['group'] == group.$1 &&
                matches('${entry.$2['name']} ${entry.$2['description']}'))
              box(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    abilityHeading(
                      entry.$2['name'],
                      id: entry.$1,
                      edit: () => addEntry(
                        'ability',
                        group: entry.$2['group'],
                        entryKey: entry.$1,
                        existing: entry.$2,
                      ),
                      remove: removeButton(entry.$2['name'], {entry.$1: null}),
                    ),
                    abilityDescription(
                      entry.$1,
                      customDescription(entry.$1, entry.$2),
                    ),
                  ],
                ),
              ),
        ],
      ],
    );
  }

  String spellEffect(String column, int row, int level) {
    final address = '${SheetEngine.column(10 + level)}$row';
    if (overrides.containsKey('Misc!$address')) return v(address, 'Misc');
    final custom = v(address, 'Misc');
    return custom.isNotEmpty
        ? custom
        : (rules.cell('Main', '$column$row')['note'] as String? ?? '').trim();
  }

  List<bool> spellSlots(int level, List<String> columns) {
    final saved = overrides['App!slots_$level'];
    return saved is List
        ? saved.cast<bool>()
        : [for (final column in columns) raw('${column}42') == true];
  }

  Future<void> editSlotCount(int level, List<String> columns) async {
    final slots = spellSlots(level, columns);
    final controller = TextEditingController(text: '${slots.length}');
    String? error;
    bool busy = false;
    editing = true;
    try {
      await finishDialog(
        (ctx) => StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            title: Text('Level $level Spell Slots'),
            content: TextField(
              key: ValueKey('slot-count-$level'),
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number Of Slots',
                errorText: error,
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final count = int.tryParse(controller.text);
                        if (count == null || count < 0 || count > 30) {
                          set(() => error = 'Enter a number from 0 to 30.');
                          return;
                        }
                        set(() => busy = true);
                        try {
                          await commit({
                            'App!slots_$level': [
                              for (var i = 0; i < count; i++)
                                i < slots.length ? slots[i] : false,
                            ],
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          set(() {
                            busy = false;
                            error = '$e';
                          });
                        }
                      },
                child: Text(busy ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      editing = false;
      controller.dispose();
    }
  }

  Widget spellbook() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Spellbook',
        sub: '${v('F41')} • Filled tomes are checked spell slots',
      ),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          key: const ValueKey('toggle-all-spells'),
          onPressed: () {
            final ids = spellIds,
                collapse = spellIds.every(expandedSpells.contains);
            setState(() {
              expandedSpells.clear();
              if (!collapse) expandedSpells.addAll(ids);
            });
          },
          icon: Icon(
            spellIds.every(expandedSpells.contains)
                ? Icons.unfold_less
                : Icons.unfold_more,
          ),
          label: Text(
            spellIds.every(expandedSpells.contains)
                ? 'Collapse All'
                : 'Expand All',
          ),
        ),
      ),
      const SizedBox(height: 12),
      const SpellLegend(),
      const SizedBox(height: 16),
      searchBox(),
      const SizedBox(height: 12),
      for (final group in [
        (0, 'G', 'F', <String>[]),
        (1, 'N', 'M', ['M', 'N', 'O', 'P']),
        (2, 'U', 'T', ['T', 'U', 'V']),
        (3, 'AB', 'AA', ['AA', 'AB', 'AC']),
        (4, 'AI', 'AH', ['AH', 'AI', 'AJ']),
        (5, 'AP', 'AO', ['AO', 'AP']),
        (6, 'AW', 'AV', ['AV']),
        (7, 'BD', 'BC', <String>[]),
        (8, 'BK', 'BJ', <String>[]),
        (9, 'BR', 'BQ', <String>[]),
      ])
        spellLevel(group.$1, group.$2, group.$3, group.$4),
    ],
  );
  Widget spellLevel(
    int level,
    String column,
    String actionColumn,
    List<String> columns,
  ) {
    final slots = spellSlots(level, columns);
    return box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                level == 0 ? 'CANTRIPS' : 'LEVEL $level',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (level > 0)
                TextButton.icon(
                  key: ValueKey('edit-slots-$level'),
                  onPressed: () => editSlotCount(level, columns),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('Slots: ${slots.length}'),
                ),
              TextButton.icon(
                key: ValueKey('add-spell-$level'),
                onPressed: () => addEntry('spell', level: level),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Spell'),
              ),
            ],
          ),
          if (slots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < slots.length; i++)
                    TomeCheckbox(
                      checked: slots[i],
                      label: 'Level $level Spell Slot ${i + 1}',
                      onChanged: (checked) async {
                        try {
                          if (overrides['App!slots_$level'] is List) {
                            await commit({
                              'App!slots_$level': [
                                for (var n = 0; n < slots.length; n++)
                                  n == i ? checked : slots[n],
                              ],
                            });
                          } else {
                            await commit({'Main!${columns[i]}42': checked});
                          }
                        } catch (e) {
                          notify(e);
                        }
                      },
                    ),
                ],
              ),
            ),
          for (var r = 44; r <= 52; r++)
            if (v('$column$r').isNotEmpty &&
                matches(
                  '${v('$column$r')} ${spellEffect(column, r, level)}',
                )) ...[
              const Divider(),
              SpellCard(
                key: ValueKey('spell-$column$r'),
                name: v('$column$r'),
                note: spellEffect(column, r, level),
                sourceName:
                    rules.cell('Main', '$column$r')['formattedValue'] ??
                    v('$column$r'),
                actionHint: v('$actionColumn$r'),
                expanded: expandedSpells.contains('$column$r'),
                onExpansionChanged: (expanded) => setState(() {
                  if (expanded) {
                    expandedSpells.add('$column$r');
                  } else {
                    expandedSpells.remove('$column$r');
                  }
                }),
                editor: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    inlineField(
                      'Misc',
                      '${SheetEngine.column(10 + level)}$r',
                      'Description',
                      text: spellEffect(column, r, level),
                      display: SpellDetails.parse(
                        v('$column$r'),
                        spellEffect(column, r, level),
                        sourceName: rules.cell(
                          'Main',
                          '$column$r',
                        )['formattedValue'],
                        actionHint: v('$actionColumn$r'),
                      ).body,
                    ),
                    if (!calculationLinked('Main', '$column$r'))
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () => editFields('Rename Spell', {
                                'Main!$column$r': 'Name',
                              }),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Rename Spell'),
                            ),
                            removeButton(v('$column$r'), {
                              'Main!$column$r': '',
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          for (final entry in appEntries('spell'))
            if (entry.$2['level'] == level &&
                matches('${entry.$2['name']} ${entry.$2['description']}')) ...[
              const Divider(),
              SpellCard(
                key: ValueKey('spell-${entry.$1}'),
                name: entry.$2['name'],
                sourceName: entry.$2['name'],
                note: entry.$2['description'],
                expanded: expandedSpells.contains(entry.$1),
                onExpansionChanged: (expanded) => setState(() {
                  if (expanded) {
                    expandedSpells.add(entry.$1);
                  } else {
                    expandedSpells.remove(entry.$1);
                  }
                }),
                editor: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customDescription(
                      entry.$1,
                      entry.$2,
                      display: SpellDetails.parse(
                        entry.$2['name'],
                        entry.$2['description'],
                      ).body,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => addEntry(
                              'spell',
                              level: level,
                              entryKey: entry.$1,
                              existing: entry.$2,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Spell'),
                          ),
                          removeButton(entry.$2['name'], {entry.$1: null}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget inventory() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Equipment & inventory',
        sub: '${v('BM36')} lb • Carried weight ${v('BX36')} lb',
      ),
      searchBox(),
      const SizedBox(height: 12),
      EquipmentView(
        query: search,
        slots: [
          for (var row = 4; row <= 16; row++)
            EquipmentSlot(
              id: row,
              label: v('BM$row'),
              item: v('BQ$row'),
              description: v('A$row', 'Misc').isNotEmpty
                  ? v('A$row', 'Misc')
                  : v('BQ$row') ==
                        rules.cell('Main', 'BQ$row')['formattedValue']
                  ? rules.cell('Main', 'BQ$row')['note'] ?? ''
                  : '',
            ),
        ],
        onEdit: (row) => editFields('Equipment Slot', {
          'Main!BQ$row': 'Item Name',
          'Misc!A$row': 'Custom Item Details (Blank Uses Source Description)',
        }),
      ),
      const SizedBox(height: 12),
      pack(),
    ],
  );
  Widget pack() {
    final firstEmpty = [
      for (var r = 18; r <= 35; r++)
        if (v('BM$r').isEmpty) r,
    ].firstOrNull;
    return box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(
            'Pack',
            sub: 'Weight is per item; quantity is included in carried weight.',
          ),
          LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                key: const ValueKey('pack-table'),
                width: constraints.maxWidth >= 800
                    ? constraints.maxWidth / 2
                    : constraints.maxWidth,
                child: DirectEditor(
                  key: ValueKey('pack-${record?['id'] ?? 'local'}'),
                  name: 'Pack',
                  values: {
                    for (var r = 18; r <= 35; r++) ...{
                      packQuantityKey(r): packQuantity(overrides, r),
                      'Main!BM$r': raw('BM$r'),
                      'Main!BX$r': raw('BX$r'),
                    },
                  },
                  integers: {for (var r = 18; r <= 35; r++) packQuantityKey(r)},
                  numbers: {for (var r = 18; r <= 35; r++) 'Main!BX$r'},
                  onEditingChanged: (value) => markDraft('pack', value),
                  onSave: (changes) => commit({
                    ...changes,
                    for (var r = 18; r <= 35; r++)
                      if (changes.containsKey('Main!BM$r') &&
                          '${changes['Main!BM$r'] ?? ''}'.trim().isEmpty) ...{
                        'Main!BX$r': null,
                        packQuantityKey(r): null,
                      },
                  }),
                  builder: (context, draft) => Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 54,
                            child: Center(child: textLabel('Qty')),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: textLabel('Item'),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Center(child: textLabel('Weight each')),
                          ),
                        ],
                      ),
                      for (var r = 18; r <= 35; r++)
                        if ((v('BM$r').isNotEmpty && matches(v('BM$r'))) ||
                            (r == firstEmpty && search.isEmpty))
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 54,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: SheetPalette.of(context).border,
                                        width: .7,
                                      ),
                                    ),
                                  ),
                                  child: draft.field(
                                    packQuantityKey(r),
                                    'Quantity for pack item ${r - 17}',
                                    align: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: draft.field(
                                      'Main!BM$r',
                                      'Pack item ${r - 17}',
                                      hint: 'Add pack item…',
                                      maxLines: 3,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: SheetPalette.of(context).border,
                                        width: .7,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: draft.field(
                                          'Main!BX$r',
                                          'Weight in pounds per item ${r - 17}',
                                          align: TextAlign.end,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Text('lb'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool matches(String s) =>
      search.isEmpty || s.toLowerCase().contains(search.toLowerCase());
  Widget searchBox() => TextField(
    onChanged: (s) => setState(() => search = s),
    decoration: const InputDecoration(
      hintText: 'Find A Name Or Description…',
      prefixIcon: Icon(Icons.search),
    ),
  );
  Widget workshop() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Rules workshop',
        sub:
            'Every imported field, formula, and source note stays inspectable.',
      ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: copyBackup,
            icon: const Icon(Icons.copy),
            label: const DiceText('Copy Character Backup'),
          ),
          OutlinedButton.icon(
            onPressed: importBackup,
            icon: const Icon(Icons.restore),
            label: const DiceText('Restore Backup'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      searchBox(),
      const SizedBox(height: 12),
      for (final sheet in ['Main', 'Stats', 'Abilities', 'Misc', 'Code'])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: box(
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: DiceText(
                sheet == 'Code' ? 'Rules tables (read only)' : sheet,
              ),
              children: [
                for (final entry in (source!['sheets'][sheet] as Map).entries)
                  if (matches(
                    '$sheet ${entry.key} ${entry.value['formattedValue']} ${entry.value['note'] ?? ''}',
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: DiceText(
                        '$sheet!${entry.key}   ${v(entry.key, sheet)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle:
                          entry.value['userEnteredValue']?['formulaValue'] !=
                              null
                          ? DiceText(
                              entry.value['userEnteredValue']['formulaValue'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: SheetPalette.of(context).muted,
                              ),
                            )
                          : entry.value['note'] != null
                          ? DiceText(
                              entry.value['note'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing:
                          entry.value['userEnteredValue']?['formulaValue'] !=
                                  null ||
                              sheet == 'Code'
                          ? const Icon(Icons.lock_outline, size: 16)
                          : IconButton(
                              onPressed: () => editFields('Edit source field', {
                                '$sheet!${entry.key}': '$sheet!${entry.key}',
                              }),
                              icon: const Icon(Icons.edit_outlined, size: 17),
                            ),
                    ),
              ],
            ),
          ),
        ),
    ],
  );
  Future<void> copyBackup() async {
    await Clipboard.setData(
      ClipboardData(
        text: jsonEncode({
          'format': 'five-zero-v1',
          'sourceId': source!['spreadsheetId'],
          'character': v('B2'),
          'overrides': overrides,
        }),
      ),
    );
    notify(
      'Character backup copied. Paste it into a private file to keep a backup.',
    );
  }

  Future<void> importBackup() async {
    final c = TextEditingController();
    String? error;
    bool busy = false;
    editing = true;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const DiceText('Restore character backup'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DiceText(
                  'This replaces editable values for the current character. The server records the changes in its history.',
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: c,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: 'Paste Backup JSON',
                    errorText: error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const DiceText('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      set(() => busy = true);
                      try {
                        final data = jsonDecode(c.text);
                        if (data['format'] != 'five-zero-v1' ||
                            data['sourceId'] != source!['spreadsheetId']) {
                          throw const FormatException(
                            'This is not a compatible 5.0 backup.',
                          );
                        }
                        final incoming = Map<String, dynamic>.from(
                          data['overrides'],
                        );
                        final changes = <String, dynamic>{};
                        for (final k in {...overrides.keys, ...incoming.keys}) {
                          final p = k.split('!');
                          if (p.length != 2 ||
                              p[0] == 'Code' ||
                              rules.cell(
                                    p[0],
                                    p[1],
                                  )['userEnteredValue']?['formulaValue'] !=
                                  null) {
                            throw const FormatException(
                              'Backup contains a locked field.',
                            );
                          }
                          final base = SheetEngine(
                            source!['sheets'],
                          ).value(p[0], p[1]);
                          changes[k] = incoming.containsKey(k)
                              ? incoming[k]
                              : base;
                        }
                        if (changes.isNotEmpty) await commit(changes);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        set(() {
                          error = '$e';
                          busy = false;
                        });
                      }
                    },
              child: DiceText(busy ? 'Restoring…' : 'Restore'),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    editing = false;
  }

  Widget activity() => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Character history',
          sub: local
              ? 'Last 100 edits on this device'
              : 'Last 100 saved events • recorded by the server',
        ),
        if (history.isEmpty)
          const DiceText(
            'No edits yet. Your first saved change will appear here.',
          ),
        for (final entry in history)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiceText(
                  '${entry['actor']} • ${entry['action']}',
                  style: TextStyle(color: SheetPalette.of(context).accent),
                ),
                DiceText(
                  '${DateTime.tryParse('${entry['at']}')?.toLocal() ?? entry['at']}',
                  style: TextStyle(
                    color: SheetPalette.of(context).muted,
                    fontSize: 12,
                  ),
                ),
                for (final change in (entry['changes'] as Map? ?? {}).entries)
                  DiceText(
                    '${change.key}: ${SheetEngine.text(change.value)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
  Widget dmDesk() => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'DM desk',
          sub:
              'Create player accounts and assign characters. All edits are attributed.',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: createPlayer,
              icon: const Icon(Icons.person_add_outlined),
              label: const DiceText('Create Player'),
            ),
            OutlinedButton.icon(
              onPressed: createCharacter,
              icon: const Icon(Icons.add),
              label: const DiceText('Create Character'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        for (final c in roster)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: DiceText(c['name']),
            subtitle: DiceText(
              'Owner: ${c['owner']} • revision ${c['revision']}',
            ),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: 'Assign Owner',
                  onPressed: () => assignOwner(c),
                  icon: const Icon(Icons.manage_accounts_outlined),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await refresh(selectId: c['id']);
                      setState(() => page = 'Overview');
                    } catch (e) {
                      notify(e);
                    }
                  },
                  child: const DiceText('Open'),
                ),
              ],
            ),
          ),
        const Divider(),
        for (final p in people) line(p['username'], p['role']),
      ],
    ),
  );
  Future<void> assignOwner(dynamic character) async {
    String owner = character['owner'];
    await simpleServerDialog(
      'Assign character owner',
      [
        DropdownButtonFormField<String>(
          initialValue: owner,
          decoration: const InputDecoration(labelText: 'Owner'),
          items: people
              .map(
                (p) => DropdownMenuItem<String>(
                  value: p['username'],
                  child: DiceText(p['username']),
                ),
              )
              .toList(),
          onChanged: (v) => owner = v!,
        ),
        const SizedBox(height: 12),
        const DiceText(
          'The previous owner loses access. The DM retains access and the assignment is recorded in history.',
        ),
      ],
      () async {
        await api('POST', 'characters/${character['id']}/owner', {
          'owner': owner,
          'revision': character['revision'],
        });
        await refresh();
      },
    );
  }

  Future<void> createPlayer() async {
    final name = TextEditingController(), password = TextEditingController();
    await simpleServerDialog(
      'Create player account',
      [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password (12+ Characters)',
          ),
        ),
        const SizedBox(height: 12),
        DiceText(
          'Give these credentials to the player privately. Players can only open characters assigned to their username.',
          style: TextStyle(color: SheetPalette.of(context).muted, fontSize: 12),
        ),
      ],
      () async {
        await api('POST', 'users', {
          'username': name.text,
          'password': password.text,
        });
        await refresh();
      },
    );
    name.dispose();
    password.dispose();
  }

  Future<void> createCharacter() async {
    final name = TextEditingController(text: 'New adventurer');
    String owner = people.first['username'];
    await simpleServerDialog(
      'Create from the Rags reference',
      [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Character Name'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: owner,
          items: people
              .map(
                (p) => DropdownMenuItem<String>(
                  value: p['username'],
                  child: DiceText(p['username']),
                ),
              )
              .toList(),
          onChanged: (v) => owner = v!,
          decoration: const InputDecoration(labelText: 'Player Owner'),
        ),
        const SizedBox(height: 12),
        DiceText(
          'Starts with Rags’ stats and abilities so the imported rules stay intact. Edit them to build the new character.',
          style: TextStyle(color: SheetPalette.of(context).muted, fontSize: 12),
        ),
      ],
      () async {
        final result = await api('POST', 'characters', {
          'name': name.text,
          'owner': owner,
        });
        await refresh(selectId: result['id']);
      },
    );
    name.dispose();
  }

  Future<void> simpleServerDialog(
    String title,
    List<Widget> fields,
    Future<void> Function() save,
  ) async {
    editing = true;
    String? error;
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: DiceText(title),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...fields,
                if (error != null)
                  DiceText(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const DiceText('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      set(() => busy = true);
                      try {
                        await save();
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        set(() {
                          busy = false;
                          error = '$e';
                        });
                      }
                    },
              child: DiceText(busy ? 'Saving…' : 'Create'),
            ),
          ],
        ),
      ),
    );
    editing = false;
  }
}

class EditDialog extends StatefulWidget {
  final String title;
  final Map<String, String> fields;
  final SheetEngine engine;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const EditDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.engine,
    required this.onSave,
  });
  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  final controllers = <String, TextEditingController>{};
  final values = <String, dynamic>{};
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    for (final k in widget.fields.keys) {
      final p = k.split('!');
      values[k] = widget.engine.value(p[0], p[1]);
      controllers[k] = TextEditingController(text: SheetEngine.text(values[k]));
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: DiceText(widget.title),
    content: SizedBox(
      width: 550,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in widget.fields.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: field(e.key, e.value),
              ),
            if (error != null)
              SelectableText(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const DiceText('Cancel'),
      ),
      FilledButton(
        onPressed: busy ? null : save,
        child: DiceText(busy ? 'Saving…' : 'Save Changes'),
      ),
    ],
  );
  Widget field(String key, String label) {
    final p = key.split('!'), cell = widget.engine.cell(p[0], p[1]);
    final condition = cell['dataValidation']?['condition'];
    if (cell['userEnteredValue']?['formulaValue'] != null) {
      return ListTile(
        title: DiceText(titleCaseLabel(label)),
        subtitle: const DiceText('Calculated • edit its inputs instead'),
        trailing: const Icon(Icons.lock),
      );
    }
    if (values[key] is bool) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: DiceText(titleCaseLabel(label)),
        value: values[key] == true,
        onChanged: busy ? null : (v) => setState(() => values[key] = v),
      );
    }
    if (condition?['type'] == 'ONE_OF_LIST') {
      return DropdownButtonFormField<String>(
        initialValue: values[key],
        isExpanded: true,
        decoration: InputDecoration(labelText: titleCaseLabel(label)),
        items: (condition['values'] as List)
            .map(
              (v) => DropdownMenuItem<String>(
                value: v['userEnteredValue'],
                child: DiceText(v['userEnteredValue']),
              ),
            )
            .toList(),
        onChanged: busy ? null : (v) => values[key] = v,
      );
    }
    return TextField(
      controller: controllers[key],
      enabled: !busy,
      minLines: 1,
      maxLines: label.toLowerCase().contains('description') ? 8 : 3,
      keyboardType: values[key] is num
          ? const TextInputType.numberWithOptions(signed: true, decimal: true)
          : TextInputType.multiline,
      decoration: InputDecoration(
        labelText: titleCaseLabel(label),
        helperText: cell['note'],
      ),
    );
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final changes = <String, dynamic>{};
      for (final key in widget.fields.keys) {
        final p = key.split('!'), cell = widget.engine.cell(p[0], p[1]);
        if (cell['userEnteredValue']?['formulaValue'] != null) continue;
        dynamic next = values[key];
        if (next is! bool &&
            cell['dataValidation']?['condition']?['type'] != 'ONE_OF_LIST') {
          final t = controllers[key]!.text;
          next = t.isEmpty
              ? null
              : next is num
              ? num.parse(t)
              : num.tryParse(t) ?? t;
        }
        if (next != widget.engine.value(p[0], p[1])) changes[key] = next;
      }
      if (changes.isNotEmpty) await widget.onSave(changes);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString().replaceFirst('Exception: ', '');
          busy = false;
        });
      }
    }
  }
}

class LoginScreen extends StatefulWidget {
  final Future<void> Function(String, String) onLogin;
  final Future<void> Function() onExplore;
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onExplore,
  });
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final name = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() => busy = true);
    try {
      await widget.onLogin(name.text, password.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      actions: const [AppearanceToggle(), SizedBox(width: 12)],
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DiceText(
                '5.0',
                style: TextStyle(
                  fontSize: 90,
                  color: SheetPalette.of(context).accent,
                ),
              ),
              const DiceText(
                'Your character.\nReady for the table.',
                style: TextStyle(fontSize: 34, height: 1.2),
              ),
              const SizedBox(height: 16),
              DiceText(
                'A shared ledger for players and their Dungeon Master.',
                style: TextStyle(color: SheetPalette.of(context).muted),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: name,
                enabled: !busy,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                enabled: !busy,
                obscureText: true,
                onSubmitted: (_) => busy ? null : signIn(),
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: DiceText(
                    error!.replaceFirst('Exception: ', ''),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy ? null : signIn,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DiceText(busy ? 'Signing In…' : 'Enter Campaign'),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: busy ? null : widget.onExplore,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: DiceText('Explore The Rags Reference Locally'),
                ),
              ),
              const SizedBox(height: 12),
              DiceText(
                'Local exploration saves only on this device. Shared characters require the campaign server and a DM-created account.',
                style: TextStyle(
                  color: SheetPalette.of(context).muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
