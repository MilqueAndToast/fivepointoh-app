import 'character_data.dart';

/// The sheet remains the rule specification. Formulas are parsed, never eval'd.
class SheetEngine {
  final Map<String, dynamic> sheets;
  final Map<String, dynamic> overrides;
  final Map<String, dynamic> _cache = {};
  final Set<String> _evaluating = {};
  final Map<String, String> errors = {};
  SheetEngine(this.sheets, [Map<String, dynamic>? values])
    : overrides = values ?? {};

  Map<String, dynamic> cell(String sheet, String address) =>
      Map<String, dynamic>.from(sheets[sheet]?[address] ?? {});
  String key(String sheet, String address) => '$sheet!$address';

  /// Static references include every branch, even when IF currently skips it.
  late final Set<String> calculationInputs = _calculationInputs();
  bool calculationLinked(String sheet, String address) =>
      cell(sheet, address)['userEnteredValue']?['formulaValue'] != null ||
      calculationInputs.contains(key(sheet, address));

  Set<String> _calculationInputs() {
    final result = <String>{};
    void visit(_Node node, String sheet) {
      if (node.kind == 'ref') {
        final parts = node.data.toString().split('!');
        result.add(
          key(
            parts.length == 2 ? parts.first : sheet,
            parts.last.replaceAll(r'$', '').toUpperCase(),
          ),
        );
      } else if (node.kind == 'range') {
        final a = node.args.first.data.toString().split('!');
        final b = node.args.last.data.toString().split('!');
        final start = _coordinates(a.last), end = _coordinates(b.last);
        for (var r = start.$2; r <= end.$2; r++) {
          for (var c = start.$1; c <= end.$1; c++) {
            result.add(key(a.length == 2 ? a.first : sheet, '${column(c)}$r'));
          }
        }
      } else {
        for (final child in node.args) {
          visit(child, sheet);
        }
      }
    }

    for (final sheet in sheets.entries) {
      for (final cell in (sheet.value as Map).values) {
        final formula = cell['userEnteredValue']?['formulaValue'];
        if (formula != null) visit(_Parser(formula).parse(), sheet.key);
      }
    }
    return Set.unmodifiable(result);
  }

  dynamic value(String sheet, String address) {
    address = address.replaceAll(r'$', '').toUpperCase();
    final k = key(sheet, address);
    if (overrides.containsKey(k)) return overrides[k];
    if (_cache.containsKey(k)) return _cache[k];
    if (!_evaluating.add(k)) throw FormatException('Circular reference: $k');
    try {
      final entered = cell(sheet, address)['userEnteredValue'] ?? {};
      dynamic result;
      if (entered['formulaValue'] != null) {
        result = _eval(_Parser(entered['formulaValue']).parse(), sheet);
        // Extend the imported weight sum with per-item quantities. With no
        // quantity edits, every row is one and the source formula is unchanged.
        if (sheet == 'Main' && address == 'BX36') {
          result =
              number(result) +
              [
                for (var row = 18; row <= 35; row++)
                  number(value('Main', 'BX$row')) *
                      (packQuantity(overrides, row) - 1),
              ].fold<num>(0, (a, b) => a + b);
        }
      } else {
        result =
            entered['numberValue'] ??
            entered['stringValue'] ??
            entered['boolValue'];
      }
      _cache[k] = result;
      return result;
    } catch (e) {
      errors[k] = e.toString();
      rethrow;
    } finally {
      _evaluating.remove(k);
    }
  }

  String display(String sheet, String address) {
    try {
      return text(value(sheet, address));
    } catch (_) {
      return 'Rule error';
    }
  }

  static String text(dynamic v) {
    if (v == null) return '';
    if (v is bool) return v ? 'TRUE' : 'FALSE';
    if (v is num && v == v.roundToDouble()) return v.toInt().toString();
    return '$v';
  }

  static num number(dynamic v) {
    if (v == null || v == '') return 0;
    if (v is num) return v;
    if (v is bool) return v ? 1 : 0;
    final parsed = num.tryParse('$v'.trim());
    if (parsed == null) throw FormatException('Expected number, got $v');
    return parsed;
  }

  static bool truth(dynamic v) => v is bool
      ? v
      : v == null || v == ''
      ? false
      : number(v) != 0;
  static bool equal(dynamic a, dynamic b) {
    if ((a == null || a == '') &&
        (b == null || b == '' || b == false || b == 0)) {
      return true;
    }
    if ((b == null || b == '') && (a == false || a == 0)) return true;
    if (a is String && b is String) return a.toLowerCase() == b.toLowerCase();
    return a == b;
  }

  dynamic _eval(_Node n, String sheet) {
    if (n.kind == 'literal') return n.data;
    if (n.kind == 'ref') {
      final p = (n.data as String).split('!');
      return value(p.length == 2 ? p[0] : sheet, p.last);
    }
    if (n.kind == 'range') {
      final a = n.args[0].data.toString().split('!');
      final b = n.args[1].data.toString().split('!');
      final sh = a.length == 2 ? a.first : sheet;
      final start = _coordinates(a.last), end = _coordinates(b.last);
      return [
        for (var r = start.$2; r <= end.$2; r++)
          [
            for (var c = start.$1; c <= end.$1; c++)
              value(sh, '${column(c)}$r'),
          ],
      ];
    }
    if (n.kind == 'unary') {
      final v = number(_eval(n.args[0], sheet));
      return n.data == '-' ? -v : v;
    }
    if (n.kind == 'binary') {
      final a = _eval(n.args[0], sheet), b = _eval(n.args[1], sheet);
      switch (n.data) {
        case '&':
          return text(a) + text(b);
        case '=':
          return equal(a, b);
        case '<>':
          return !equal(a, b);
        case '+':
          return number(a) + number(b);
        case '-':
          return number(a) - number(b);
        case '*':
          return number(a) * number(b);
        case '/':
          if (number(b) == 0) throw const FormatException('Division by zero');
          return number(a) / number(b);
        case '>=':
          return number(a) >= number(b);
        case '<=':
          return number(a) <= number(b);
        case '>':
          return number(a) > number(b);
        case '<':
          return number(a) < number(b);
      }
    }
    if (n.kind == 'call') {
      dynamic arg(int i) => i < n.args.length ? _eval(n.args[i], sheet) : null;
      switch (n.data) {
        case 'IF':
          return truth(arg(0))
              ? arg(1)
              : n.args.length > 2
              ? arg(2)
              : false;
        case 'OR':
          return n.args.any((a) => truth(_eval(a, sheet)));
        case 'IMAGE':
          return ''; // Presentation only; never fetch tokenized image URLs.
        case 'SUM':
          return _numbers(
            n.args.map((a) => _eval(a, sheet)),
          ).fold<num>(0, (a, b) => a + b);
        case 'PRODUCT':
          final nums = _numbers(n.args.map((a) => _eval(a, sheet))).toList();
          return nums.isEmpty ? 0 : nums.fold<num>(1, (a, b) => a * b);
        case 'INT':
          return number(arg(0)).floor();
        case 'FLOOR':
          final significance = n.args.length > 1 ? number(arg(1)) : 1;
          return (number(arg(0)) / significance).floor() * significance;
        case 'QUOTIENT':
          return (number(arg(0)) / number(arg(1))).truncate();
        case 'VLOOKUP':
          if (truth(arg(3))) {
            throw const FormatException('Approximate lookup is unsupported');
          }
          final rows = arg(1) as List;
          final columnIndex = number(arg(2)).toInt() - 1;
          for (final row in rows) {
            if (equal(row[0], arg(0))) return row[columnIndex];
          }
          throw FormatException('Lookup not found: ${arg(0)}');
        default:
          throw FormatException('Unsupported function ${n.data}');
      }
    }
    throw FormatException('Unknown formula node ${n.kind}');
  }

  Iterable<num> _numbers(Iterable<dynamic> values) sync* {
    for (final v in values) {
      if (v is Iterable) {
        yield* _numbers(v);
      } else if (v is num) {
        yield v;
      }
    }
  }

  static (int, int) _coordinates(String a) {
    final m = RegExp(r'^\$?([A-Z]+)\$?(\d+)$').firstMatch(a.toUpperCase());
    if (m == null) throw FormatException('Invalid cell $a');
    var col = 0;
    for (final c in m[1]!.codeUnits) {
      col = col * 26 + c - 64;
    }
    return (col, int.parse(m[2]!));
  }

  static String column(int c) {
    var result = '';
    for (; c > 0; c = (c - 1) ~/ 26) {
      result = String.fromCharCode(65 + (c - 1) % 26) + result;
    }
    return result;
  }
}

class _Node {
  final String kind;
  final dynamic data;
  final List<_Node> args;
  _Node(this.kind, [this.data, this.args = const []]);
}

class _Parser {
  final String source;
  final List<String> tokens = [];
  int i = 0;
  _Parser(this.source) {
    final input = source.startsWith('=') ? source.substring(1) : source;
    final re = RegExp(
      r'\s*("(?:[^"]|"")*"|(?:[A-Za-z_][A-Za-z_0-9 ]*!|\x27[^\x27]*\x27!)?\$?[A-Za-z]+\$?\d+|[A-Za-z_][A-Za-z_0-9.]*|\d*\.\d+|\d+|>=|<=|<>|[+*/&=<>():,\-])',
    );
    var offset = 0;
    while (offset < input.length) {
      if (input.substring(offset).trim().isEmpty) break;
      final m = re.matchAsPrefix(input, offset);
      if (m == null) {
        throw FormatException(
          'Invalid formula near ${input.substring(offset)}',
        );
      }
      tokens.add(m[1]!);
      offset = m.end;
    }
  }
  String get peek => i < tokens.length ? tokens[i] : '';
  String take() => i < tokens.length
      ? tokens[i++]
      : throw const FormatException('Unexpected end');
  void expect(String token) {
    if (take() != token) throw FormatException('Expected $token');
  }

  _Node parse() {
    final n = expression(0);
    // The reference contains redundant closing parentheses in size formulas.
    while (peek == ')') {
      i++;
    }
    if (i != tokens.length) throw FormatException('Unexpected token $peek');
    return n;
  }

  int precedence(String s) => switch (s) {
    ':' => 6,
    '*' => 5,
    '/' => 5,
    '+' => 4,
    '-' => 4,
    '&' => 3,
    '=' => 2,
    '<>' => 2,
    '>' => 2,
    '<' => 2,
    '>=' => 2,
    '<=' => 2,
    _ => -1,
  };
  _Node expression(int minimum) {
    var left = primary();
    while (precedence(peek) >= minimum) {
      final op = take(), right = expression(precedence(op) + 1);
      left = _Node(op == ':' ? 'range' : 'binary', op, [left, right]);
    }
    return left;
  }

  _Node primary() {
    if (peek == ',' || peek == ')' || peek == '') return _Node('literal');
    final t = take();
    if (t == '-' || t == '+') return _Node('unary', t, [expression(6)]);
    if (t == '(') {
      final n = expression(0);
      expect(')');
      return n;
    }
    if (t.startsWith('"')) {
      return _Node(
        'literal',
        t.substring(1, t.length - 1).replaceAll('""', '"'),
      );
    }
    final number = num.tryParse(t);
    if (number != null) return _Node('literal', number);
    if (peek == '(') {
      take();
      final args = <_Node>[];
      if (peek != ')') {
        do {
          args.add(expression(0));
          if (peek != ',') break;
          take();
        } while (true);
      }
      expect(')');
      return _Node('call', t.toUpperCase(), args);
    }
    if (t.toUpperCase() == 'TRUE' || t.toUpperCase() == 'FALSE') {
      return _Node('literal', t.toUpperCase() == 'TRUE');
    }
    return _Node('ref', t.replaceAll("'", ''));
  }
}
