/// 模块：JSON 解析辅助（data/models）
/// 作用：集中处理彩云/高德接口中"类型不稳定"的字段（num/String/List/空数组）。
/// 依赖：纯 Dart。
library;

Map<String, dynamic> asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

Map<String, dynamic>? asMapOrNull(dynamic value) =>
    value is Map<String, dynamic> ? value : null;

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

String? asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

int? asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<double> asDoubleList(dynamic value) {
  if (value is! List) return const <double>[];
  return value
      .whereType<num>()
      .map((e) => e.toDouble())
      .toList(growable: false);
}
