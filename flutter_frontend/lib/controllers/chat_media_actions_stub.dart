import '../models/app_models.dart';

Future<ChatAttachmentDraft?> pickChatAttachment(String messageType) async {
  // Media attachments are web-first in this build.
  // 当前构建中的媒体附件能力以 Web 为主。
  return null;
}

void openChatAttachment({
  required String mediaMime,
  required String mediaData,
}) {
  // No-op outside the web build.
  // Web 构建之外保持空实现。
}
