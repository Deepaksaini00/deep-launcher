import 'package:flutter/material.dart';

import 'icon_choice.dart';
import 'packs/cupertino.dart';
import 'packs/font_awesome.dart';
import 'packs/line_awesome.dart';
import 'packs/material.dart';

const Map<String, IconData> _customIcons = {
  // ==== App / Utility Icons ====
  'flashlight': Icons.flashlight_on_outlined,
  'file': Icons.insert_drive_file_outlined,
  'security': Icons.security_outlined,
  // ==== Social / Communication ====
  'message': Icons.message_outlined,
  'chat': Icons.chat_bubble_outline,
  'mail': Icons.mail_outline,
  'people': Icons.people_outline,
  'notifications': Icons.notifications_none,

  // ==== Media ====
  'video': Icons.videocam_outlined,
  'gallery': Icons.photo_library_outlined,
  'game': Icons.sports_esports_outlined,
  'mic': Icons.mic_none_outlined,
  "podcast": Icons.podcasts,
  "music": Icons.music_note,

  // ==== Tools ====
  'alarm': Icons.alarm_outlined,
  'timer': Icons.timer_outlined,
  'calculator': Icons.calculate_outlined,
  'bookmark': Icons.bookmark_outline,
  'note': Icons.note_outlined,
  'edit': Icons.edit_outlined,

  // ==== Navigation / Maps ====
  'directions': Icons.directions_outlined,
  'location': Icons.location_on_outlined,
  'compass': Icons.explore_outlined,

  // ==== Shopping / Money ====
  'shopping_cart': Icons.shopping_cart_outlined,
  'shop': Icons.storefront_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'currency_rupee': Icons.currency_rupee_outlined,

  // ==== System Status ====
  'storage': Icons.storage_outlined,

  // ==== Browsers & Internet ====
  'search': Icons.search_outlined,
  'language': Icons.language,

  // ==== Entertainment ====
  "instagram": Icons.camera_alt,
  "yt": Icons.play_circle_fill,

  // ==== Documents ====
  'description': Icons.description_outlined,
  "task_done": Icons.task_alt,
  // === General =====
  'camera': Icons.camera_outlined,
  'call': Icons.call_outlined,
  'map': Icons.map_outlined,
  'folder': Icons.folder_outlined,
  'calendar': Icons.calendar_month_outlined,

  'photo_camera': Icons.photo_camera_outlined,
  'credit_card': Icons.credit_card_outlined,
  'payments': Icons.payments_outlined,
  'payment': Icons.payment_outlined,
  'wb_twilight': Icons.wb_twilight_outlined,
  'fitbit': Icons.fitbit,
  'history_edu': Icons.history_edu_outlined,
  'sync': Icons.sync,
  'sync_alt': Icons.sync_alt,
  'place': Icons.place_outlined,
  'web': Icons.web_outlined,
  'calendar_today': Icons.calendar_today_outlined,
  'date_range': Icons.date_range_outlined,
  'schedule': Icons.schedule_outlined,
  'folder_copy': Icons.folder_copy,
};

/// Every icon the launcher offers, keyed by a stable string slug. This merges
/// the original hand-picked icons with the full Material, Cupertino,
/// Font Awesome and Line Awesome packs.
final Map<String, IconData> icons = <String, IconData>{
  for (final e in allIcons.entries) e.key: e.value.data,
  for (final e in cupertinoIcons.entries) e.key: e.value.data,
  for (final e in fontAwesomeIcons.entries) e.key: e.value.data,
  for (final e in lineAwesomeIcons.entries) e.key: e.value.data,
  ..._customIcons,
};

/// All icon choices (pack + name + data) for the picker.
final List<IconChoice> searchableIcons = <IconChoice>[
  ...allIcons.values,
  ...cupertinoIcons.values,
  ...fontAwesomeIcons.values,
  ...lineAwesomeIcons.values,
];

final List<IconChoice> allIconChoices = <IconChoice>[
  ..._customIcons.entries.map(
    (e) => IconChoice(name: e.key, data: e.value, pack: 'custom'),
  ),
  ...searchableIcons,
];

/// A small curated set of commonly used icons shown by default in the picker,
/// so the dialog isn't overloaded with thousands of entries.
final List<String> preferredIconKeys = <String>[
  'gallery',
  'message',
  'chat',
  'mail',
  'call',
  'camera',
  'photo_camera',
  'video',
  'music',
  'music_note_outlined',
  'game',
  'mic',
  'wallet',
  'shopping_cart',
  'payments',
  'payment',
  'credit_card',
  'map',
  'place',
  'location_on',
  'directions',
  'web',
  'search',
  'language',
  'settings',
  'lock',
  'alarm',
  'timer',
  'calculator',
  'bookmark',
  'edit',
  'note',
  'description',
  'folder',
  'folder_open',
  'file',
  'download',
  'upload',
  'cloud',
  'notifications',
  'headphones',
  'headset',
  'phone',
  'home',
  'star',
  'favorite',
  'apps',
];

String? iconDataToName(IconData icon) {
  for (final (entry) in icons.entries) {
    if (entry.value == icon) {
      return entry.key;
    }
  }
  return null;
}
