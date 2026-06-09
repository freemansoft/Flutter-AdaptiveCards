import 'package:flutter/material.dart';

/// Material [IconData] pair for Fluent **Filled** and **Regular** styles.
class FluentIconEntry {
  /// Creates a Fluent icon mapping entry.
  const FluentIconEntry({
    required this.filled,
    this.regular,
  });

  /// Filled variant (default Teams `style`).
  final IconData filled;

  /// Outlined / regular variant when Material provides one.
  final IconData? regular;
}

/// Normalizes Fluent icon names for case-insensitive lookup.
///
/// Strips spaces, underscores, and hyphens so `AccessTime` and `access_time`
/// resolve the same way.
String normalizeFluentIconName(String name) =>
    name.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();

/// Built-in Fluent name → Material icon lookup (~50 common names).
///
/// Unknown names return `null`; callers should fall back to [Icons.help_outline].
const Map<String, FluentIconEntry> kFluentIconMap = {
  'accesstime': FluentIconEntry(
    filled: Icons.access_time,
    regular: Icons.access_time_outlined,
  ),
  'add': FluentIconEntry(filled: Icons.add, regular: Icons.add_outlined),
  'arrowdown': FluentIconEntry(
    filled: Icons.arrow_downward,
    regular: Icons.arrow_downward_outlined,
  ),
  'arrowleft': FluentIconEntry(
    filled: Icons.arrow_back,
    regular: Icons.arrow_back_outlined,
  ),
  'arrowright': FluentIconEntry(
    filled: Icons.arrow_forward,
    regular: Icons.arrow_forward_outlined,
  ),
  'arrowup': FluentIconEntry(
    filled: Icons.arrow_upward,
    regular: Icons.arrow_upward_outlined,
  ),
  'attach': FluentIconEntry(
    filled: Icons.attach_file,
    regular: Icons.attach_file_outlined,
  ),
  'bell': FluentIconEntry(
    filled: Icons.notifications,
    regular: Icons.notifications_outlined,
  ),
  'bug': FluentIconEntry(
    filled: Icons.bug_report,
    regular: Icons.bug_report_outlined,
  ),
  'calendar': FluentIconEntry(
    filled: Icons.calendar_today,
    regular: Icons.calendar_today_outlined,
  ),
  'call': FluentIconEntry(filled: Icons.call, regular: Icons.call_outlined),
  'camera': FluentIconEntry(
    filled: Icons.camera_alt,
    regular: Icons.camera_alt_outlined,
  ),
  'chat': FluentIconEntry(filled: Icons.chat, regular: Icons.chat_outlined),
  'checkmark': FluentIconEntry(
    filled: Icons.check,
    regular: Icons.check_outlined,
  ),
  'chevrondown': FluentIconEntry(filled: Icons.expand_more),
  'chevronleft': FluentIconEntry(filled: Icons.chevron_left),
  'chevronright': FluentIconEntry(filled: Icons.chevron_right),
  'chevronup': FluentIconEntry(filled: Icons.expand_less),
  'clock': FluentIconEntry(
    filled: Icons.access_time,
    regular: Icons.access_time_outlined,
  ),
  'close': FluentIconEntry(filled: Icons.close),
  'cloud': FluentIconEntry(filled: Icons.cloud, regular: Icons.cloud_outlined),
  'code': FluentIconEntry(filled: Icons.code),
  'copy': FluentIconEntry(filled: Icons.copy, regular: Icons.copy_outlined),
  'database': FluentIconEntry(
    filled: Icons.storage,
    regular: Icons.storage_outlined,
  ),
  'delete': FluentIconEntry(
    filled: Icons.delete,
    regular: Icons.delete_outlined,
  ),
  'dismiss': FluentIconEntry(filled: Icons.close),
  'document': FluentIconEntry(
    filled: Icons.description,
    regular: Icons.description_outlined,
  ),
  'download': FluentIconEntry(
    filled: Icons.download,
    regular: Icons.download_outlined,
  ),
  'edit': FluentIconEntry(filled: Icons.edit, regular: Icons.edit_outlined),
  'errorcircle': FluentIconEntry(
    filled: Icons.error,
    regular: Icons.error_outlined,
  ),
  'eye': FluentIconEntry(
    filled: Icons.remove_red_eye,
    regular: Icons.remove_red_eye_outlined,
  ),
  'filter': FluentIconEntry(
    filled: Icons.filter_list,
    regular: Icons.filter_list_outlined,
  ),
  'flag': FluentIconEntry(filled: Icons.flag, regular: Icons.flag_outlined),
  'folder': FluentIconEntry(
    filled: Icons.folder,
    regular: Icons.folder_outlined,
  ),
  'globe': FluentIconEntry(
    filled: Icons.language,
    regular: Icons.language_outlined,
  ),
  'heart': FluentIconEntry(
    filled: Icons.favorite,
    regular: Icons.favorite_border,
  ),
  'help': FluentIconEntry(filled: Icons.help, regular: Icons.help_outlined),
  'home': FluentIconEntry(filled: Icons.home, regular: Icons.home_outlined),
  'image': FluentIconEntry(filled: Icons.image, regular: Icons.image_outlined),
  'info': FluentIconEntry(filled: Icons.info, regular: Icons.info_outlined),
  'link': FluentIconEntry(filled: Icons.link, regular: Icons.link_outlined),
  'location': FluentIconEntry(
    filled: Icons.location_on,
    regular: Icons.location_on_outlined,
  ),
  'lock': FluentIconEntry(filled: Icons.lock, regular: Icons.lock_outlined),
  'mail': FluentIconEntry(filled: Icons.mail, regular: Icons.mail_outlined),
  'map': FluentIconEntry(filled: Icons.map, regular: Icons.map_outlined),
  'menu': FluentIconEntry(filled: Icons.menu),
  'more': FluentIconEntry(filled: Icons.more_horiz),
  'open': FluentIconEntry(filled: Icons.open_in_new),
  'person': FluentIconEntry(
    filled: Icons.person,
    regular: Icons.person_outlined,
  ),
  'people': FluentIconEntry(
    filled: Icons.people,
    regular: Icons.people_outlined,
  ),
  'pin': FluentIconEntry(filled: Icons.push_pin, regular: Icons.push_pin_outlined),
  'print': FluentIconEntry(filled: Icons.print, regular: Icons.print_outlined),
  'refresh': FluentIconEntry(filled: Icons.refresh),
  'save': FluentIconEntry(filled: Icons.save, regular: Icons.save_outlined),
  'search': FluentIconEntry(
    filled: Icons.search,
    regular: Icons.search_outlined,
  ),
  'send': FluentIconEntry(filled: Icons.send, regular: Icons.send_outlined),
  'settings': FluentIconEntry(
    filled: Icons.settings,
    regular: Icons.settings_outlined,
  ),
  'share': FluentIconEntry(filled: Icons.share, regular: Icons.share_outlined),
  'sort': FluentIconEntry(filled: Icons.sort),
  'star': FluentIconEntry(filled: Icons.star, regular: Icons.star_border),
  'sync': FluentIconEntry(filled: Icons.sync),
  'thumbdislike': FluentIconEntry(
    filled: Icons.thumb_down,
    regular: Icons.thumb_down_outlined,
  ),
  'thumblike': FluentIconEntry(
    filled: Icons.thumb_up,
    regular: Icons.thumb_up_outlined,
  ),
  'unlock': FluentIconEntry(
    filled: Icons.lock_open,
    regular: Icons.lock_open_outlined,
  ),
  'upload': FluentIconEntry(
    filled: Icons.upload,
    regular: Icons.upload_outlined,
  ),
  'video': FluentIconEntry(
    filled: Icons.videocam,
    regular: Icons.videocam_outlined,
  ),
  'visibility': FluentIconEntry(
    filled: Icons.visibility,
    regular: Icons.visibility_outlined,
  ),
  'warning': FluentIconEntry(
    filled: Icons.warning,
    regular: Icons.warning_outlined,
  ),
};

/// Resolves a Fluent icon [name] to [IconData], or `null` when unknown.
IconData? resolveFluentIcon(String name, {required bool filled}) {
  final entry = kFluentIconMap[normalizeFluentIconName(name)];
  if (entry == null) {
    return null;
  }
  if (filled) {
    return entry.filled;
  }
  return entry.regular ?? entry.filled;
}

/// Maps Teams Icon `size` tokens to logical pixels.
double resolveIconSize(String? size) {
  switch (size?.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase()) {
    case 'xxsmall':
      return 12;
    case 'xsmall':
      return 14;
    case 'small':
      return 16;
    case 'medium':
      return 20;
    case 'large':
      return 24;
    case 'xlarge':
      return 32;
    case 'xxlarge':
      return 40;
    case 'standard':
    default:
      return 20;
  }
}
