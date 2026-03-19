import '../models/app_models.dart';

Future<PostAttachmentDraft?> pickPostAttachment(String mediaType) async {
  // Fallback for targets without a platform-specific picker.
  // 没有平台专用选择器的目标平台使用的兜底实现。
  return null;
}

void openPostAttachment({
  required String mediaMime,
  required String mediaData,
}) {
  // No-op for unsupported targets.
  // 不支持的目标平台保持空实现。
}
