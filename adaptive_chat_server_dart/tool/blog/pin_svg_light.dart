/// Pins the draw.io SVG diagrams in `blog/` to their light colours, so each
/// keeps a white background when GitHub shows it in dark mode.
///
/// draw.io writes every adaptive colour as CSS `light-dark(<light>, <dark>)`
/// and marks the root `color-scheme: light dark`. GitHub renders a committed
/// SVG inside its own page, so a reader in dark mode gets the dark half: a
/// near-black background behind a diagram drawn with black arrows. Every
/// export from draw.io brings these values back, which is why this is a tool
/// with a CI check rather than a one-off edit.
///
/// Only the rendered markup changes. The diagram model draw.io reopens lives
/// in the root's `content` attribute and carries no `light-dark()` values.
///
/// ```sh
/// fvm dart run tool/blog/pin_svg_light.dart          # rewrite blog/*.drawio.svg
/// fvm dart run tool/blog/pin_svg_light.dart --check  # exit 1 if any would change
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const _lightDark = 'light-dark(';
final _scheme = RegExp(r'color-scheme:\s*light\s+dark');

/// Returns [svg] with every `light-dark(<light>, <dark>)` replaced by its
/// light argument and `color-scheme: light dark` narrowed to `light`.
///
/// Arguments may themselves contain parentheses and commas, as in
/// `light-dark(rgb(255, 255, 255), var(--ge-dark-color, #121212))`, so they
/// are split at the top-level comma rather than by pattern. Applying it to
/// its own output changes nothing.
String pinLightColors(String svg) {
  final out = StringBuffer();
  var from = 0;
  for (var start = svg.indexOf(_lightDark); start >= 0;) {
    final call = _lightArgument(svg, start + _lightDark.length);
    out
      ..write(svg.substring(from, start))
      ..write(call.light);
    from = call.end;
    start = svg.indexOf(_lightDark, from);
  }
  out.write(svg.substring(from));
  return out.toString().replaceAll(_scheme, 'color-scheme: light');
}

/// The first argument of the call whose arguments begin at [open], and the
/// index just past its closing parenthesis.
({String light, int end}) _lightArgument(String s, int open) {
  var depth = 0;
  int? comma;
  for (var i = open; i < s.length; i++) {
    final c = s[i];
    if (c == '(') depth++;
    if (c == ',' && depth == 0) comma ??= i;
    if (c == ')' && depth-- == 0) {
      return (light: s.substring(open, comma ?? i).trim(), end: i + 1);
    }
  }
  throw FormatException('Unclosed light-dark( call', s, open);
}

/// The `*.drawio.svg` files under [dir], sorted for stable output.
List<File> drawioSvgs(Directory dir) =>
    dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.drawio.svg'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'check',
      negatable: false,
      help: 'Report files that still switch to dark colours; change nothing.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  final opts = parser.parse(args);
  if (opts['help'] as bool) {
    stdout
      ..writeln('Usage: dart run tool/blog/pin_svg_light.dart [--check] [svg…]')
      ..writeln('With no paths, every blog/*.drawio.svg.')
      ..writeln(parser.usage);
    return;
  }

  final files = opts.rest.isEmpty
      ? drawioSvgs(Directory('blog'))
      : opts.rest.map(File.new).toList();
  final stale = _pinAll(files, write: !(opts['check'] as bool));
  if (opts['check'] as bool && stale.isNotEmpty) {
    stderr
      ..writeln('These SVGs switch to dark colours in dark mode:')
      ..writeln(stale.map((f) => '  ${p.normalize(f.path)}').join('\n'))
      ..writeln('Fix with: dart run tool/blog/pin_svg_light.dart');
    exit(1);
  }
}

/// Pins each of [files], writing changes when [write] is set, and returns
/// the files that needed a change.
List<File> _pinAll(List<File> files, {required bool write}) {
  final stale = <File>[];
  for (final file in files) {
    final svg = file.readAsStringSync();
    final pinned = pinLightColors(svg);
    if (pinned == svg) continue;
    stale.add(file);
    if (write) {
      file.writeAsStringSync(pinned);
      stdout.writeln('pinned ${p.normalize(file.path)}');
    }
  }
  return stale;
}
