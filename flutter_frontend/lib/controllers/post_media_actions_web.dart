// Web-only post media picker; dart:html is used here for the browser file dialog.
// Web 端帖子媒体选择器；这里使用 dart:html 触发浏览器文件选择框。
// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import '../models/app_models.dart';

Future<PostAttachmentDraft?> pickPostAttachment(String mediaType) async {
  // Let the browser pick an image or short video and keep its raw bytes.
  // 让浏览器选择图片或小视频，并保留其原始字节。
  final input = html.FileUploadInputElement()
    ..accept = _acceptFor(mediaType)
    ..multiple = false;
  input.click();

  final change = input.onChange.first;
  await change;
  final file = input.files?.first;
  if (file == null) {
    return null;
  }

  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoadEnd.first;

  final result = reader.result;
  if (result is! ByteBuffer) {
    return null;
  }

  final bytes = Uint8List.view(result);
  final mime = file.type.isNotEmpty
      ? file.type
      : _mimeFor(mediaType, file.name);
  final normalizedType = _normalizeMediaType(mediaType, mime, file.name);
  return PostAttachmentDraft(
    mediaType: normalizedType,
    mediaName: file.name,
    mediaMime: mime,
    mediaData: base64Encode(bytes),
    originalSizeBytes: bytes.length,
  );
}

void openPostAttachment({
  required String mediaMime,
  required String mediaData,
}) {
  // Open a post attachment in a new browser tab for quick review.
  // 在新浏览器标签页中打开帖子附件，方便快速查看。
  if (mediaData.isEmpty) {
    return;
  }
  try {
    final normalizedMime = mediaMime.isEmpty || mediaMime.contains('*')
        ? 'application/octet-stream'
        : mediaMime;
    final url = Uri.dataFromBytes(
      base64Decode(mediaData),
      mimeType: normalizedMime,
    ).toString();
    html.window.open(url, '_blank');
  } catch (_) {
    // Keep the page responsive even if the media payload is malformed.
    // 即使媒体载荷有误，也保持页面可继续使用。
  }
}

String _acceptFor(String mediaType) {
  switch (mediaType) {
    case 'video':
      return 'video/*';
    case 'image':
    default:
      return 'image/*';
  }
}

String _mimeFor(String mediaType, String fileName) {
  switch (mediaType) {
    case 'video':
      return _mimeFromFileName(fileName, 'video/mp4');
    case 'image':
    default:
      return _mimeFromFileName(fileName, 'image/png');
  }
}

String _mimeFromFileName(String fileName, String fallback) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.gif')) {
    return 'image/gif';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.mp4')) {
    return 'video/mp4';
  }
  if (lower.endsWith('.mov')) {
    return 'video/quicktime';
  }
  if (lower.endsWith('.webm')) {
    return 'video/webm';
  }
  if (lower.endsWith('.mkv')) {
    return 'video/x-matroska';
  }
  return fallback;
}

String _normalizeMediaType(String mediaType, String mime, String fileName) {
  final normalized = mediaType.toLowerCase().trim();
  if (normalized == 'image' || normalized == 'video') {
    return normalized;
  }
  if (mime.startsWith('video/')) {
    return 'video';
  }
  if (mime.startsWith('image/')) {
    return 'image';
  }
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mkv')) {
    return 'video';
  }
  return 'image';
}
