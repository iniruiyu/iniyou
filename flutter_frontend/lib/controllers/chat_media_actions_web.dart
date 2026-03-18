// Web-only attachment picker; dart:html is still used here for the browser file dialog.
// Web 端附件选择器；这里仍使用 dart:html 触发浏览器文件选择框。
// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/app_models.dart';

Future<ChatAttachmentDraft?> pickChatAttachment(String messageType) async {
  // Use the browser file picker and keep the selected payload as raw bytes.
  // 使用浏览器文件选择器并将所选载荷保持为原始字节。
  final input = html.FileUploadInputElement()
    ..accept = _acceptFor(messageType)
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
      : _mimeFor(messageType, file.name);
  final normalizedType = _normalizeMessageType(messageType, mime, file.name);
  final compressedBytes = _compressBytes(bytes);

  return ChatAttachmentDraft(
    messageType: normalizedType,
    mediaName: file.name,
    mediaMime: mime,
    mediaData: base64Encode(compressedBytes),
    originalSizeBytes: bytes.length,
  );
}

void openChatAttachment({
  required String mediaMime,
  required String mediaData,
}) {
  // Open the decoded raw media payload in a new browser tab.
  // 在新的浏览器标签页中打开解码后的原始媒体载荷。
  if (mediaData.isEmpty) {
    return;
  }
  try {
    final rawBytes = base64Decode(mediaData);
    final decodedBytes = _decompressBytes(rawBytes);
    final normalizedMime = mediaMime.isEmpty || mediaMime.contains('*')
        ? 'application/octet-stream'
        : mediaMime;
    final url = Uri.dataFromBytes(
      decodedBytes,
      mimeType: normalizedMime,
    ).toString();
    html.window.open(url, '_blank');
  } catch (_) {
    // Ignore decode errors and keep the UI responsive.
    // 忽略解码错误，保持界面可继续使用。
  }
}

Uint8List _compressBytes(Uint8List bytes) {
  // Compress attachment payloads before base64 encoding.
  // 在进行 base64 编码前压缩附件载荷。
  try {
    return Uint8List.fromList(GZipEncoder().encode(bytes));
  } catch (_) {
    return bytes;
  }
}

Uint8List _decompressBytes(Uint8List bytes) {
  // Restore compressed payloads when opening or previewing attachments.
  // 在打开或预览附件时还原压缩载荷。
  try {
    return Uint8List.fromList(GZipDecoder().decodeBytes(bytes));
  } catch (_) {
    return bytes;
  }
}

String _acceptFor(String messageType) {
  switch (messageType) {
    case 'image':
      return 'image/*';
    case 'video':
      return 'video/*';
    case 'audio':
      return 'audio/*';
    default:
      return '*/*';
  }
}

String _mimeFor(String messageType, String fileName) {
  switch (messageType) {
    case 'image':
      return _mimeFromFileName(fileName, 'image/png');
    case 'video':
      return _mimeFromFileName(fileName, 'video/mp4');
    case 'audio':
      return _mimeFromFileName(fileName, 'audio/mpeg');
    default:
      final ext = fileName.toLowerCase();
      if (ext.endsWith('.png') ||
          ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.gif') ||
          ext.endsWith('.webp')) {
        return _mimeFromFileName(fileName, 'image/png');
      }
      if (ext.endsWith('.mp4') ||
          ext.endsWith('.mov') ||
          ext.endsWith('.webm') ||
          ext.endsWith('.mkv')) {
        return _mimeFromFileName(fileName, 'video/mp4');
      }
      if (ext.endsWith('.mp3') ||
          ext.endsWith('.wav') ||
          ext.endsWith('.ogg') ||
          ext.endsWith('.m4a') ||
          ext.endsWith('.aac')) {
        return _mimeFromFileName(fileName, 'audio/mpeg');
      }
      return 'application/octet-stream';
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
  if (lower.endsWith('.mp3')) {
    return 'audio/mpeg';
  }
  if (lower.endsWith('.wav')) {
    return 'audio/wav';
  }
  if (lower.endsWith('.ogg')) {
    return 'audio/ogg';
  }
  if (lower.endsWith('.m4a')) {
    return 'audio/mp4';
  }
  if (lower.endsWith('.aac')) {
    return 'audio/aac';
  }
  return fallback;
}

String _normalizeMessageType(String messageType, String mime, String fileName) {
  final normalized = messageType.toLowerCase().trim();
  if (normalized == 'text' ||
      normalized == 'image' ||
      normalized == 'video' ||
      normalized == 'audio') {
    return normalized;
  }
  if (mime.startsWith('image/')) {
    return 'image';
  }
  if (mime.startsWith('video/')) {
    return 'video';
  }
  if (mime.startsWith('audio/')) {
    return 'audio';
  }
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp')) {
    return 'image';
  }
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.webm')) {
    return 'video';
  }
  if (lower.endsWith('.mp3') ||
      lower.endsWith('.wav') ||
      lower.endsWith('.ogg')) {
    return 'audio';
  }
  return 'text';
}
