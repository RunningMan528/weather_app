// 模块：架构约束校验器（架构守卫 / architecture fitness function）
// 作用：把 docs/04_Flutter_架构与脚手架_详解.md 第三节的分层与依赖规则变成可执行检查，
//       在 CI 里拦住"顺手 import"式的破坏。
// 运行：dart run tool/check_architecture.dart（有违规时退出码非 0）
// 为什么需要它：架构靠口头约定一定会退化；把规则写成可执行测试，才能在新人、赶工期、
//   重构时都保持边界。新增一条规则的成本应该很低（本文件加一个 Rule 即可）。
// 局限：静态文本分析（正则匹配 import），不做语义分析；跨库（package）拆分后需扩展扫描范围。

import 'dart:io';

/// 一条架构规则。
class Rule {
  const Rule({
    required this.id,
    required this.description,
    required this.check,
  });

  final String id;
  final String description;

  /// 返回违规说明列表（空表示通过）。
  final List<String> Function(List<SourceFile> files) check;
}

/// 源码文件（含路径、层级信息与 import 列表）。
class SourceFile {
  SourceFile(this.path, this.content)
    : imports = _parseImports(content),
      code = _stripComments(content),
      lineCount = content.split('\n').length;

  final String path;
  final String content;

  /// 去掉注释后的代码：避免"注释里提到 fromJson"被误判为违规。
  final String code;

  final List<String> imports;
  final int lineCount;

  static final RegExp _importPattern = RegExp(
    r'''^\s*import\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  static List<String> _parseImports(String content) =>
      _importPattern.allMatches(content).map((m) => m.group(1)!).toList();

  /// 去行注释与块注释（足够覆盖本项目的写法；不追求完整词法分析）。
  static String _stripComments(String content) => content
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'//.*$'), ''))
      .join('\n');

  /// 把 import 解析成"相对项目根"的路径；包外依赖返回 null。
  ///
  /// 关键：项目内部大量使用相对导入（`../../auth/...`），
  /// 如果不做路径归一化，跨模块规则会漏检——这正是本项目曾经的盲区。
  String? resolveImport(String import) {
    if (import.startsWith('dart:')) return null;
    if (import.startsWith('package:')) {
      final selfPrefix = 'package:$_packageName/';
      return import.startsWith(selfPrefix)
          ? import.substring(selfPrefix.length)
          : null; // 第三方包
    }
    final segments = <String>[
      ...path.substring(0, path.lastIndexOf('/')).split('/'),
    ];
    for (final part in import.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (segments.isNotEmpty) segments.removeLast();
      } else {
        segments.add(part);
      }
    }
    return segments.join('/');
  }

  /// 全部 import 的解析结果（跳过第三方包与 dart: 前缀）。
  List<String> get resolvedImports =>
      imports.map(resolveImport).whereType<String>().toList();

  bool get isDomain => path.contains('/domain/');
  bool get isData => path.contains('/data/');
  bool get isPresentation => path.contains('/presentation/');
  bool get isViewModel => path.contains('/presentation/viewmodel/');
  bool get isEntity => path.contains('/domain/entities/');
  bool get isCore => path.startsWith('lib/core/');
  bool get isFeature => path.startsWith('lib/features/');

  /// 所属模块名（`features/<name>/...` → `<name>`），非 feature 返回 null。
  String? get feature {
    if (!isFeature) return null;
    final parts = path.split('/');
    return parts.length > 2 ? parts[2] : null;
  }

  /// 从解析后的路径里取出所属模块名（`features/<name>/...`）。
  static String? featureOf(String resolvedPath) {
    final match = RegExp(r'(?:^|/)features/([^/]+)/').firstMatch(resolvedPath);
    return match?.group(1);
  }

  bool importsFlutter(List<String> patterns) =>
      imports.any((i) => patterns.any(i.startsWith));

  /// 当前工程的包名（从 pubspec.yaml 读取），用于解析 package: 自身导入。
  static final String _packageName = _readPackageName();

  static String _readPackageName() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return '';
    final match = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec.readAsStringSync());
    return match?.group(1) ?? '';
  }
}

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('未找到 lib/ 目录，请在项目根目录运行');
    exit(2);
  }

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // 生成代码不参与检查（由生成器保证一致性）。
      .where(
        (f) => !f.path.endsWith('.g.dart') && !f.path.endsWith('.freezed.dart'),
      )
      .map((f) => SourceFile(f.path, f.readAsStringSync()))
      .toList();

  var violations = 0;
  for (final rule in rules) {
    final problems = rule.check(files);
    if (problems.isEmpty) {
      stdout.writeln('  [PASS] ${rule.id} ${rule.description}');
      continue;
    }
    violations += problems.length;
    stdout.writeln('  [FAIL] ${rule.id} ${rule.description}');
    for (final problem in problems) {
      stdout.writeln('         - $problem');
    }
  }

  stdout.writeln('');
  stdout.writeln('扫描 ${files.length} 个文件，违规 $violations 处');
  if (violations > 0) exit(1);
}

/// 全部架构规则。
final List<Rule> rules = <Rule>[
  Rule(
    id: 'R1',
    description: 'domain 层不得依赖 Flutter（内层不感知框架）',
    check: (files) => [
      for (final f in files)
        if (f.isDomain && f.importsFlutter(['package:flutter/']))
          '${f.path} 在 domain 层引入了 Flutter',
    ],
  ),
  Rule(
    id: 'R2',
    description: 'domain 层不得依赖 data / presentation',
    check: (files) => [
      for (final f in files)
        if (f.isDomain &&
            f.imports.any(
              (i) =>
                  i.contains('/data/') ||
                  i.contains('/presentation/') ||
                  i.contains('features/') && i.contains('/data/'),
            ))
          '${f.path} 的 domain 层引用了 data/presentation',
    ],
  ),
  Rule(
    id: 'R3',
    description: 'data 层不得依赖 presentation',
    check: (files) => [
      for (final f in files)
        if (f.isData && f.imports.any((i) => i.contains('presentation/')))
          '${f.path} 的 data 层引用了 presentation',
    ],
  ),
  Rule(
    id: 'R4',
    description: 'ViewModel 不得直接依赖 data 层（只能依赖 domain 与 core）',
    check: (files) => [
      for (final f in files)
        if (f.isViewModel && f.imports.any((i) => i.contains('/data/')))
          '${f.path} 的 ViewModel 直接引用了 data 层（应改为依赖用例/契约）',
    ],
  ),
  Rule(
    id: 'R5',
    description: 'core 不得依赖 features（基础设施不能反向依赖业务）',
    check: (files) => [
      for (final f in files)
        if (f.isCore && f.imports.any((i) => i.contains('features/')))
          '${f.path} 的 core 引用了 features',
    ],
  ),
  Rule(
    id: 'R6',
    description: '跨模块引用只允许 domain 契约与公共组件，禁止引用其它模块的 data / viewmodel',
    check: (files) {
      final problems = <String>[];
      for (final f in files) {
        final owner = f.feature;
        if (owner == null) continue; // app / shell 属于组合层，允许装配 features
        for (final resolved in f.resolvedImports) {
          final target = SourceFile.featureOf(resolved);
          if (target == null || target == owner) continue;
          final illegal =
              resolved.contains('/data/') ||
              resolved.contains('/presentation/viewmodel/') ||
              resolved.contains('/presentation/state/');
          if (illegal) {
            problems.add('${f.path} 引用了模块 $target 的内部实现（$resolved）');
          }
        }
      }
      return problems;
    },
  ),
  Rule(
    id: 'R7',
    description: '领域实体不得包含 JSON 映射（fromJson/toJson 只能在 data 层）',
    check: (files) {
      final declaration = RegExp(
        r'(factory\s+\w+\.fromJson|Map<String,\s*dynamic>\s+toJson|static\s+Map<String,\s*dynamic>\s+\w*[Tt]oJson)',
      );
      return [
        for (final f in files)
          if (f.isEntity && declaration.hasMatch(f.code))
            '${f.path} 的实体包含 JSON 映射声明（应移到 data/models）',
      ];
    },
  ),
  Rule(
    id: 'R8',
    description: '单文件不超过 400 行（防止 God file 与职责膨胀）',
    check: (files) => [
      for (final f in files)
        if (f.lineCount > 400) '${f.path} 有 ${f.lineCount} 行（> 400）',
    ],
  ),
];
