import 'package:flutter/material.dart';

const icons = {
  // ==== App / Utility Icons ====
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
  'qr_code': Icons.qr_code_2_outlined,

  // ==== Browsers & Internet ====
  'search': Icons.search_outlined,
  'public': Icons.public_outlined,
  'language': Icons.language,

  // ==== Entertainment ====
  'star': Icons.star_border_outlined,
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
  'calculate': Icons.calculate_outlined,
  'schedule': Icons.schedule_outlined,
  'folder_copy': Icons.folder_copy,
};

String? iconDataToName(IconData icon) {
  for (final (entry) in icons.entries) {
    if (entry.value == icon) {
      return entry.key;
    }
  }
  return null;
}
