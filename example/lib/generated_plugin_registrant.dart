//
// Generated file. Do not edit.
//

// ignore: unused_import
import 'dart:ui';

import 'package:import_js_library/import_js_library.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:wakelock_web/wakelock_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(PluginRegistry registry) {
  ImportJsLibrary.registerWith(registry.registrarFor(ImportJsLibrary));
  SharedPreferencesPlugin.registerWith(registry.registrarFor(SharedPreferencesPlugin));
  UrlLauncherPlugin.registerWith(registry.registrarFor(UrlLauncherPlugin));
  VideoPlayerPlugin.registerWith(registry.registrarFor(VideoPlayerPlugin));
  WakelockWeb.registerWith(registry.registrarFor(WakelockWeb));
  registry.registerMessageHandler();
}
