/// App-specific character data. Inventory quantities extend carried weight;
/// descriptions and spell-slot controls remain independent of sheet formulas.
String packQuantityKey(int row) => 'App!pack_quantity_$row';
num packQuantity(Map<String, dynamic> values, int row) {
  final key = packQuantityKey(row), value = values[key];
  if (value == null) return 1;
  validateAppField(key, value);
  return value as num;
}

void validateAppField(String key, dynamic value) {
  if (RegExp(r'^App!pack_quantity_(1[89]|2[0-9]|3[0-5])$').hasMatch(key)) {
    if (value == null) return;
    if (value is! num ||
        !value.isFinite ||
        value < 0 ||
        value != value.roundToDouble()) {
      throw const FormatException(
        'Quantity must be a nonnegative whole number.',
      );
    }
    return;
  }
  if (RegExp(r'^App!slots_[1-9]$').hasMatch(key)) {
    if (value == null) return;
    if (value is! List || value.length > 30 || value.any((v) => v is! bool)) {
      throw const FormatException(
        'Spell slots must be a list of up to 30 checkboxes.',
      );
    }
    return;
  }
  if (!RegExp(r'^App!entry_[a-zA-Z0-9_]{1,64}$').hasMatch(key)) {
    throw const FormatException('Unknown character field.');
  }
  if (value == null) return;
  if (value is! Map ||
      !{'spell', 'ability'}.contains(value['kind']) ||
      value.keys.any(
        (k) => !{'kind', 'name', 'description', 'level', 'group'}.contains(k),
      )) {
    throw const FormatException('Invalid character entry.');
  }
  for (final field in ['name', 'description']) {
    final text = value[field];
    if (text is! String ||
        text.length > (field == 'name' ? 160 : 12000) ||
        text.startsWith('=')) {
      throw const FormatException('Invalid entry text.');
    }
  }
  if ((value['name'] as String).trim().isEmpty) {
    throw const FormatException('An entry needs a name.');
  }
  if (value['kind'] == 'spell') {
    if (value['level'] is! int ||
        value['level'] < 0 ||
        value['level'] > 9 ||
        value.containsKey('group')) {
      throw const FormatException('Choose a spell level from 0 to 9.');
    }
  } else if (!{
        'Class',
        'Trade',
        'Feats',
        'Ancestry',
      }.contains(value['group']) ||
      value.containsKey('level')) {
    throw const FormatException('Choose an ability group.');
  }
}
