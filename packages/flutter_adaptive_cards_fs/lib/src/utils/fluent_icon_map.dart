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
  'pin': FluentIconEntry(
    filled: Icons.push_pin,
    regular: Icons.push_pin_outlined,
  ),
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

  // --- expanded canonical Fluent names (2026-06-28) ---
  'play': FluentIconEntry(filled: Icons.play_arrow),
  'pause': FluentIconEntry(filled: Icons.pause),
  'stop': FluentIconEntry(filled: Icons.stop),
  'next': FluentIconEntry(filled: Icons.skip_next),
  'previous': FluentIconEntry(filled: Icons.skip_previous),
  'fastforward': FluentIconEntry(filled: Icons.fast_forward),
  'rewind': FluentIconEntry(filled: Icons.fast_rewind),
  'volume': FluentIconEntry(filled: Icons.volume_up),
  'mute': FluentIconEntry(filled: Icons.volume_off),
  'mic': FluentIconEntry(filled: Icons.mic, regular: Icons.mic_none),
  'micoff': FluentIconEntry(filled: Icons.mic_off),
  'bookmark': FluentIconEntry(
    filled: Icons.bookmark,
    regular: Icons.bookmark_border,
  ),
  'bookmarks': FluentIconEntry(
    filled: Icons.bookmarks,
    regular: Icons.bookmarks_outlined,
  ),
  'favorite': FluentIconEntry(
    filled: Icons.favorite,
    regular: Icons.favorite_border,
  ),
  'cart': FluentIconEntry(
    filled: Icons.shopping_cart,
    regular: Icons.shopping_cart_outlined,
  ),
  'store': FluentIconEntry(
    filled: Icons.store,
    regular: Icons.store_outlined,
  ),
  'creditcard': FluentIconEntry(filled: Icons.credit_card),
  'money': FluentIconEntry(filled: Icons.attach_money),
  'wallet': FluentIconEntry(
    filled: Icons.account_balance_wallet,
    regular: Icons.account_balance_wallet_outlined,
  ),
  'bank': FluentIconEntry(filled: Icons.account_balance),
  'work': FluentIconEntry(filled: Icons.work, regular: Icons.work_outline),
  'school': FluentIconEntry(
    filled: Icons.school,
    regular: Icons.school_outlined,
  ),
  'book': FluentIconEntry(filled: Icons.book, regular: Icons.book_outlined),
  'dashboard': FluentIconEntry(
    filled: Icons.dashboard,
    regular: Icons.dashboard_outlined,
  ),
  'analytics': FluentIconEntry(
    filled: Icons.analytics,
    regular: Icons.analytics_outlined,
  ),
  'chart': FluentIconEntry(
    filled: Icons.insert_chart,
    regular: Icons.insert_chart_outlined,
  ),
  'piechart': FluentIconEntry(
    filled: Icons.pie_chart,
    regular: Icons.pie_chart_outline,
  ),
  'barchart': FluentIconEntry(filled: Icons.bar_chart),
  'linechart': FluentIconEntry(filled: Icons.show_chart),
  'trendingup': FluentIconEntry(filled: Icons.trending_up),
  'trendingdown': FluentIconEntry(filled: Icons.trending_down),
  'table': FluentIconEntry(
    filled: Icons.table_chart,
    regular: Icons.table_chart_outlined,
  ),
  'grid': FluentIconEntry(
    filled: Icons.grid_view,
    regular: Icons.grid_view_outlined,
  ),
  'list': FluentIconEntry(filled: Icons.format_list_bulleted),
  'numberedlist': FluentIconEntry(filled: Icons.format_list_numbered),
  'lightbulb': FluentIconEntry(
    filled: Icons.lightbulb,
    regular: Icons.lightbulb_outline,
  ),
  'verified': FluentIconEntry(
    filled: Icons.verified,
    regular: Icons.verified_outlined,
  ),
  'shield': FluentIconEntry(
    filled: Icons.shield,
    regular: Icons.shield_outlined,
  ),
  'security': FluentIconEntry(filled: Icons.security),
  'fingerprint': FluentIconEntry(filled: Icons.fingerprint),
  'key': FluentIconEntry(
    filled: Icons.vpn_key,
    regular: Icons.vpn_key_outlined,
  ),
  'badge': FluentIconEntry(
    filled: Icons.badge,
    regular: Icons.badge_outlined,
  ),
  'account': FluentIconEntry(
    filled: Icons.account_circle,
    regular: Icons.account_circle_outlined,
  ),
  'personadd': FluentIconEntry(filled: Icons.person_add),
  'trophy': FluentIconEntry(
    filled: Icons.emoji_events,
    regular: Icons.emoji_events_outlined,
  ),
  'emoji': FluentIconEntry(
    filled: Icons.emoji_emotions,
    regular: Icons.emoji_emotions_outlined,
  ),
  'comment': FluentIconEntry(
    filled: Icons.comment,
    regular: Icons.comment_outlined,
  ),
  'forum': FluentIconEntry(
    filled: Icons.forum,
    regular: Icons.forum_outlined,
  ),
  'feedback': FluentIconEntry(
    filled: Icons.feedback,
    regular: Icons.feedback_outlined,
  ),
  'reply': FluentIconEntry(filled: Icons.reply),
  'forward': FluentIconEntry(filled: Icons.forward),
  'inbox': FluentIconEntry(filled: Icons.inbox),
  'archive': FluentIconEntry(
    filled: Icons.archive,
    regular: Icons.archive_outlined,
  ),
  'drafts': FluentIconEntry(
    filled: Icons.drafts,
    regular: Icons.drafts_outlined,
  ),
  'cloudupload': FluentIconEntry(
    filled: Icons.cloud_upload,
    regular: Icons.cloud_upload_outlined,
  ),
  'clouddownload': FluentIconEntry(
    filled: Icons.cloud_download,
    regular: Icons.cloud_download_outlined,
  ),
  'clouddone': FluentIconEntry(
    filled: Icons.cloud_done,
    regular: Icons.cloud_done_outlined,
  ),
  'backup': FluentIconEntry(filled: Icons.backup),
  'restore': FluentIconEntry(filled: Icons.restore),
  'history': FluentIconEntry(filled: Icons.history),
  'remove': FluentIconEntry(
    filled: Icons.remove_circle,
    regular: Icons.remove_circle_outline,
  ),
  'cancel': FluentIconEntry(filled: Icons.cancel),
  'block': FluentIconEntry(filled: Icons.block),
  'checkcircle': FluentIconEntry(
    filled: Icons.check_circle,
    regular: Icons.check_circle_outline,
  ),
  'pending': FluentIconEntry(
    filled: Icons.pending,
    regular: Icons.pending_outlined,
  ),
  'visibilityoff': FluentIconEntry(
    filled: Icons.visibility_off,
    regular: Icons.visibility_off_outlined,
  ),
  'notificationsoff': FluentIconEntry(
    filled: Icons.notifications_off,
    regular: Icons.notifications_off_outlined,
  ),
  'calendarevent': FluentIconEntry(filled: Icons.event),
  'alarm': FluentIconEntry(filled: Icons.alarm),
  'timer': FluentIconEntry(
    filled: Icons.timer,
    regular: Icons.timer_outlined,
  ),
  'update': FluentIconEntry(filled: Icons.update),
  'label': FluentIconEntry(filled: Icons.label, regular: Icons.label_outline),
  'tag': FluentIconEntry(filled: Icons.sell, regular: Icons.sell_outlined),
  'gift': FluentIconEntry(filled: Icons.card_giftcard),
  'cake': FluentIconEntry(filled: Icons.cake),
  'celebration': FluentIconEntry(filled: Icons.celebration),
  'palette': FluentIconEntry(
    filled: Icons.palette,
    regular: Icons.palette_outlined,
  ),
  'color': FluentIconEntry(
    filled: Icons.color_lens,
    regular: Icons.color_lens_outlined,
  ),
  'brush': FluentIconEntry(filled: Icons.brush),
  'text': FluentIconEntry(filled: Icons.text_fields),
  'bold': FluentIconEntry(filled: Icons.format_bold),
  'italic': FluentIconEntry(filled: Icons.format_italic),
  'underline': FluentIconEntry(filled: Icons.format_underlined),
  'build': FluentIconEntry(filled: Icons.build, regular: Icons.build_outlined),
  'handyman': FluentIconEntry(filled: Icons.handyman),
  'qrcode': FluentIconEntry(filled: Icons.qr_code),
  'scan': FluentIconEntry(filled: Icons.document_scanner),
  'wifi': FluentIconEntry(filled: Icons.wifi),
  'bluetooth': FluentIconEntry(filled: Icons.bluetooth),
  'battery': FluentIconEntry(filled: Icons.battery_full),
  'power': FluentIconEntry(filled: Icons.power_settings_new),
  'desktop': FluentIconEntry(filled: Icons.desktop_windows),
  'laptop': FluentIconEntry(filled: Icons.laptop),
  'mobile': FluentIconEntry(filled: Icons.smartphone),
  'tablet': FluentIconEntry(filled: Icons.tablet),
  'tv': FluentIconEntry(filled: Icons.tv),
  'keyboard': FluentIconEntry(filled: Icons.keyboard),
  'mouse': FluentIconEntry(filled: Icons.mouse),
  'compass': FluentIconEntry(
    filled: Icons.explore,
    regular: Icons.explore_outlined,
  ),
  'navigation': FluentIconEntry(filled: Icons.navigation),
  'directions': FluentIconEntry(filled: Icons.directions),
  'car': FluentIconEntry(
    filled: Icons.directions_car,
    regular: Icons.directions_car_outlined,
  ),
  'flight': FluentIconEntry(filled: Icons.flight),
  'train': FluentIconEntry(filled: Icons.train),
  'bus': FluentIconEntry(
    filled: Icons.directions_bus,
    regular: Icons.directions_bus_outlined,
  ),
  'walk': FluentIconEntry(filled: Icons.directions_walk),
  'bike': FluentIconEntry(filled: Icons.directions_bike),
  'hotel': FluentIconEntry(filled: Icons.hotel),
  'restaurant': FluentIconEntry(filled: Icons.restaurant),
  'coffee': FluentIconEntry(
    filled: Icons.local_cafe,
    regular: Icons.local_cafe_outlined,
  ),
  'apartment': FluentIconEntry(filled: Icons.apartment),
  'business': FluentIconEntry(filled: Icons.business),
  'weather': FluentIconEntry(
    filled: Icons.wb_sunny,
    regular: Icons.wb_sunny_outlined,
  ),
  'rain': FluentIconEntry(
    filled: Icons.water_drop,
    regular: Icons.water_drop_outlined,
  ),
  'snow': FluentIconEntry(filled: Icons.ac_unit),
  'temperature': FluentIconEntry(filled: Icons.thermostat),

  // --- aliases (author name variants) ---
  'trash': FluentIconEntry(
    filled: Icons.delete,
    regular: Icons.delete_outlined,
  ),
  'bin': FluentIconEntry(filled: Icons.delete, regular: Icons.delete_outlined),
  'gear': FluentIconEntry(
    filled: Icons.settings,
    regular: Icons.settings_outlined,
  ),
  'options': FluentIconEntry(
    filled: Icons.settings,
    regular: Icons.settings_outlined,
  ),
  'pencil': FluentIconEntry(filled: Icons.edit, regular: Icons.edit_outlined),
  'find': FluentIconEntry(
    filled: Icons.search,
    regular: Icons.search_outlined,
  ),
  'email': FluentIconEntry(filled: Icons.mail, regular: Icons.mail_outlined),
  'envelope': FluentIconEntry(filled: Icons.mail, regular: Icons.mail_outlined),
  'user': FluentIconEntry(
    filled: Icons.person,
    regular: Icons.person_outlined,
  ),
  'contact': FluentIconEntry(
    filled: Icons.person,
    regular: Icons.person_outlined,
  ),
  'group': FluentIconEntry(
    filled: Icons.people,
    regular: Icons.people_outlined,
  ),
  'team': FluentIconEntry(
    filled: Icons.people,
    regular: Icons.people_outlined,
  ),
  'photo': FluentIconEntry(filled: Icons.image, regular: Icons.image_outlined),
  'picture': FluentIconEntry(
    filled: Icons.image,
    regular: Icons.image_outlined,
  ),
  'information': FluentIconEntry(
    filled: Icons.info,
    regular: Icons.info_outlined,
  ),
  'alert': FluentIconEntry(
    filled: Icons.warning,
    regular: Icons.warning_outlined,
  ),
  'error': FluentIconEntry(
    filled: Icons.error,
    regular: Icons.error_outlined,
  ),
  'accept': FluentIconEntry(
    filled: Icons.check,
    regular: Icons.check_outlined,
  ),
  'check': FluentIconEntry(
    filled: Icons.check,
    regular: Icons.check_outlined,
  ),
  'date': FluentIconEntry(
    filled: Icons.calendar_today,
    regular: Icons.calendar_today_outlined,
  ),
  'house': FluentIconEntry(filled: Icons.home, regular: Icons.home_outlined),
  'house2': FluentIconEntry(filled: Icons.home, regular: Icons.home_outlined),
  'starfilled': FluentIconEntry(filled: Icons.star, regular: Icons.star_border),
  'question': FluentIconEntry(
    filled: Icons.help,
    regular: Icons.help_outlined,
  ),
  'idea': FluentIconEntry(
    filled: Icons.lightbulb,
    regular: Icons.lightbulb_outline,
  ),
  'trophyaward': FluentIconEntry(
    filled: Icons.emoji_events,
    regular: Icons.emoji_events_outlined,
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
