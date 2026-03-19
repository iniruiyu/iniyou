import 'package:flutter/material.dart';

import '../models/app_models.dart';

String _localizedChoice(
  String languageCode,
  String zh,
  String en, [
  String? tw,
]) {
  switch (languageCode) {
    case 'en-US':
      return en;
    case 'zh-TW':
      return tw ?? zh;
    default:
      return zh;
  }
}

List<DropdownMenuItem<String>> buildIdentityVisibilityItems(
  String languageCode,
) {
  // Shared identity visibility choices for the active language only.
  // 当前语言的身份资料可见范围选项。
  return const [
    DropdownMenuItem(
      value: 'public',
      child: Text('公开'),
    ),
    DropdownMenuItem(
      value: 'friends',
      child: Text('好友可见'),
    ),
    DropdownMenuItem(
      value: 'private',
      child: Text('仅自己'),
    ),
  ].map((item) {
    final label = switch (item.value) {
      'public' => _localizedChoice(languageCode, '公开', 'Public', '公開'),
      'friends' => _localizedChoice(languageCode, '好友可见', 'Friends only', '好友可見'),
      'private' => _localizedChoice(languageCode, '仅自己', 'Only me', '僅自己'),
      _ => '',
    };
    return DropdownMenuItem<String>(value: item.value, child: Text(label));
  }).toList(growable: false);
}

List<DropdownMenuItem<String>> buildPostVisibilityItems(String languageCode) {
  // Shared post visibility choices for the active language only.
  // 当前语言的文章可见范围选项。
  return [
    DropdownMenuItem(
      value: 'public',
      child: Text(_localizedChoice(languageCode, '公开', 'Public', '公開')),
    ),
    DropdownMenuItem(
      value: 'private',
      child: Text(_localizedChoice(languageCode, '私密', 'Private', '私密')),
    ),
  ];
}

List<DropdownMenuItem<String>> buildPostStatusItems(String languageCode) {
  // Shared post status choices for the active language only.
  // 当前语言的文章状态选项。
  return [
    DropdownMenuItem(
      value: 'published',
      child: Text(
        _localizedChoice(languageCode, '已发布', 'Published', '已發布'),
      ),
    ),
    DropdownMenuItem(
      value: 'draft',
      child: Text(_localizedChoice(languageCode, '草稿', 'Draft', '草稿')),
    ),
    DropdownMenuItem(
      value: 'hidden',
      child: Text(_localizedChoice(languageCode, '隐藏', 'Hidden', '隱藏')),
    ),
  ];
}

List<DropdownMenuItem<String>> buildSpaceTypeItems(String languageCode) {
  // Shared space type choices for the active language only.
  // 当前语言的空间类型选项。
  return [
    DropdownMenuItem(
      value: 'private',
      child: Text(
        _localizedChoice(languageCode, '私人空间', 'Private space', '私人空間'),
      ),
    ),
    DropdownMenuItem(
      value: 'public',
      child: Text(_localizedChoice(languageCode, '空间', 'Space', '空間')),
    ),
  ];
}

List<DropdownMenuItem<String>> buildSpaceVisibilityItems(String languageCode) {
  // Shared space visibility choices for the active language only.
  // 当前语言的空间可见范围选项。
  return [
    DropdownMenuItem(
      value: 'public',
      child: Text(
        _localizedChoice(languageCode, '所有人可见', 'Public', '所有人可見'),
      ),
    ),
    DropdownMenuItem(
      value: 'friends',
      child: Text(
        _localizedChoice(languageCode, '好友可见', 'Friends only', '好友可見'),
      ),
    ),
    DropdownMenuItem(
      value: 'private',
      child: Text(
        _localizedChoice(languageCode, '仅自己可见', 'Only me', '僅自己可見'),
      ),
    ),
  ];
}

List<DropdownMenuItem<String>> buildSpaceItems(
  List<SpaceItem> spaces,
) {
  // Keep the space picker labels focused on the actual space name and handle.
  // 空间选择器直接展示空间名称与句柄，避免把二级域名入口信息截断。
  return spaces
      .map(
        (space) => DropdownMenuItem<String>(
          value: space.id,
          child: Text('${space.name} · @${space.subdomain}'),
        ),
      )
      .toList();
}
