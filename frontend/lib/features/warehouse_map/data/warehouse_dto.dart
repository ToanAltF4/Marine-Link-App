import '../domain/warehouse.dart';

List<Warehouse> warehousesFromJson(dynamic json) {
  if (json is! List) return const [];
  return json.map(warehouseFromJson).toList();
}

Warehouse warehouseFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return Warehouse(
    id: _stringOrEmpty(map['id'] ?? map['publicId'] ?? map['public_id']),
    name: _stringOrEmpty(map['name']),
    address: _stringOrEmpty(map['address']),
    phone: _stringOrNull(map['phone']),
    openingHours: _stringOrNull(map['openingHours'] ?? map['opening_hours']),
    latitude: _toNum(map['latitude']).toDouble(),
    longitude: _toNum(map['longitude']).toDouble(),
    isActive: _toBool(map['isActive'] ?? map['active'] ?? map['is_active']),
  );
}

String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

String? _stringOrNull(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
