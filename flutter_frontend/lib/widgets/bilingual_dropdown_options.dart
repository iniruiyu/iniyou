import 'package:flutter/material.dart';

import '../models/app_models.dart';

List<DropdownMenuItem<String>> buildIdentityVisibilityItems() {
  // Shared identity visibility choices / 共用身份资料可见范围选项。
  return const [
    DropdownMenuItem(
      value: 'public',
      child: Text('公开 / Public'),
    ),
    DropdownMenuItem(
      value: 'friends',
      child: Text('好友可见 / Friends only'),
    ),
    DropdownMenuItem(
      value: 'private',
      child: Text('仅自己 / Only me'),
    ),
  ];
}

List<DropdownMenuItem<String>> buildPostVisibilityItems() {
  // Shared post visibility choices / 共用文章可见范围选项。
  return const [
    DropdownMenuItem(
      value: 'public',
      child: Text('公开 / Public'),
    ),
    DropdownMenuItem(
      value: 'private',
      child: Text('私密 / Private'),
    ),
  ];
}

List<DropdownMenuItem<String>> buildPostStatusItems() {
  // Shared post status choices / 共用文章状态选项。
  return const [
    DropdownMenuItem(
      value: 'published',
      child: Text('已发布 / Published'),
    ),
    DropdownMenuItem(
      value: 'draft',
      child: Text('草稿 / Draft'),
    ),
    DropdownMenuItem(
      value: 'hidden',
      child: Text('隐藏 / Hidden'),
    ),
  ];
}

List<DropdownMenuItem<String>> buildSpaceTypeItems() {
  // Shared space type choices / 共用空间类型选项。
  return const [
    DropdownMenuItem(
      value: 'private',
      child: Text('私人空间 / Private space'),
    ),
    DropdownMenuItem(
      value: 'public',
      child: Text('公共空间 / Public space'),
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
