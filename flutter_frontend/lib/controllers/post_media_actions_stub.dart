import '../models/app_models.dart';

Future<PostAttachmentDraft?> pickPostAttachment(String mediaType) async {
  // Post media picking is web-first in this build.
  // 当前构建中的帖子媒体选择以 Web 为主。
  return null;
}

void openPostAttachment({
  required String mediaMime,
  required String mediaData,
}) {
  // No-op outside the web build.
  // Web 构建之外保持空实现。
}
