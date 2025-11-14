import 'package:flutter/material.dart';

const icons = {
  // ==== App / Utility Icons ====
  'settings': Icons.settings_outlined,
  'flashlight': Icons.flashlight_on_outlined,
  'file': Icons.insert_drive_file_outlined,
  'security': Icons.security_outlined,
  'share': Icons.share_outlined,

  // ==== Social / Communication ====
  'message': Icons.message_outlined,
  'chat': Icons.chat_bubble_outline,
  'mail': Icons.mail_outline,
  'people': Icons.people_outline,
  'group': Icons.groups_outlined,
  'notifications': Icons.notifications_none,

  // ==== Media ====
  'video': Icons.videocam_outlined,
  'gallery': Icons.photo_library_outlined,
  'movie': Icons.movie_outlined,
  'game': Icons.sports_esports_outlined,
  'mic': Icons.mic_none_outlined,
  "podcast": Icons.podcasts,
  "radio": Icons.radio,
  "audio": Icons.audiotrack,
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
  'update': Icons.system_update_outlined,
  'info': Icons.info_outline,
  'qr_code': Icons.qr_code_2_outlined,

  // ==== Browsers & Internet ====
  'search': Icons.search_outlined,
  'public': Icons.public_outlined,
  'language': Icons.language,

  // ==== Entertainment ====
  'music_note': Icons.music_note,
  'star': Icons.star_border_outlined,
  'facebook': Icons.facebook,
  "instagram": Icons.camera_alt,
  "yt": Icons.play_circle_fill,

  // ==== Documents ====
  'document_scanner': Icons.document_scanner_outlined,
  'description': Icons.description_outlined,
  "todo_list": Icons.checklist,
  "task_done": Icons.task_alt,
  "event": Icons.event_note,
  // === General =====
  'camera': Icons.camera_outlined,
  'call': Icons.call_outlined,
  'map': Icons.map_outlined,
  'folder': Icons.folder_outlined,
  'calendar': Icons.calendar_month_outlined,
};

String? iconDataToName(IconData icon) {
  for (final (entry) in icons.entries) {
    if (entry.value == icon) {
      return entry.key;
    }
  }
  return null;
}
