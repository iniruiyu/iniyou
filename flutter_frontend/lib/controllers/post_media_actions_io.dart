// IO attachment picker for desktop and mobile platforms.
// 桌面端与移动端的 IO 附件选择器。
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/app_models.dart';

const int _maxImageDimension = 1600;

Future<PostAttachmentDraft?> pickPostAttachment(String mediaType) async {
  // Use the native file picker so Flutter desktop/mobile can attach media too.
  // 使用原生文件选择器，让 Flutter 桌面端和移动端也能添加媒体附件。
  final pickerType = _pickerTypeFor(mediaType);
  final result = await FilePicker.platform.pickFiles(
    type: pickerType.type,
    allowedExtensions: pickerType.allowedExtensions,
    allowMultiple: false,
    withData: true,
  );
  final file = result?.files.single;
  if (file == null) {
    return null;
  }

  final bytes = await _readBytes(file);
  if (bytes == null || bytes.isEmpty) {
    return null;
  }

  final mime = _mimeFor(mediaType, file.name);
  final normalizedType = _normalizeMediaType(mediaType, mime, file.name);
  final preparedImage = normalizedType == 'image'
      ? await _prepareImageUpload(bytes: bytes, fileName: file.name)
      : null;
  return PostAttachmentDraft(
    mediaType: normalizedType,
    mediaName: preparedImage?.fileName ?? file.name,
    mediaMime: preparedImage?.mime ?? mime,
    mediaData: base64Encode(preparedImage?.bytes ?? bytes),
    originalSizeBytes: bytes.length,
  );
}

Future<_PreparedImage?> _prepareImageUpload({
  required Uint8List bytes,
  required String fileName,
}) async {
  // Resize oversized images before upload so edit and compose flows stay bounded.
  // 在上传前缩放超大图片，让编辑和发布流程都保持可控。
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    if (image.width <= _maxImageDimension &&
        image.height <= _maxImageDimension) {
      return null;
    }

    final resizedCodec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _maxImageDimension,
      targetHeight: _maxImageDimension,
    );
    final resizedFrame = await resizedCodec.getNextFrame();
    final byteData = await resizedFrame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      return null;
    }

    return _PreparedImage(
      fileName: _replaceExtension(fileName, '.png'),
      mime: 'image/png',
      bytes: byteData.buffer.asUint8List(),
    );
  } catch (_) {
    return null;
  }
}

void openPostAttachment({
  required String mediaMime,
  required String mediaData,
}) {
  // Save the decoded payload to a temp file and ask the desktop shell to open it.
  // 将解码后的载荷写入临时文件，并交给桌面系统打开。
  if (mediaData.isEmpty) {
    return;
  }
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }

  try {
    final bytes = base64Decode(mediaData);
    final extension = _extensionForMime(mediaMime);
    final directory = Directory.systemTemp.createTempSync('iniyou_post_');
    final file = File(
      '${directory.path}${Platform.pathSeparator}attachment$extension',
    );
    file.writeAsBytesSync(bytes, flush: true);
    unawaited(_launchFile(file.path));
  } catch (_) {
    // Keep the UI responsive even if the local open helper fails.
    // 即使本地打开辅助失败，也保持界面响应。
  }
}

Future<void> _launchFile(String path) async {
  if (Platform.isWindows) {
    await Process.start('cmd', [
      '/c',
      'start',
      '',
      path,
    ], mode: ProcessStartMode.detached);
    return;
  }
  if (Platform.isMacOS) {
    await Process.start('open', [path], mode: ProcessStartMode.detached);
    return;
  }
  if (Platform.isLinux) {
    await Process.start('xdg-open', [path], mode: ProcessStartMode.detached);
  }
}

Future<Uint8List?> _readBytes(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return file.bytes;
  }
  final path = file.path;
  if (path == null || path.isEmpty) {
    return null;
  }
  return File(path).readAsBytes();
}

({FileType type, List<String> allowedExtensions}) _pickerTypeFor(
  String mediaType,
) {
  switch (mediaType) {
    case 'video':
      return (
        type: FileType.custom,
        allowedExtensions: const ['mp4', 'mov', 'webm', 'mkv'],
      );
    case 'image':
    default:
      return (
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
      );
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

String _extensionForMime(String mediaMime) {
  final normalized = mediaMime.toLowerCase();
  if (normalized.contains('png')) {
    return '.png';
  }
  if (normalized.contains('jpeg') || normalized.contains('jpg')) {
    return '.jpg';
  }
  if (normalized.contains('gif')) {
    return '.gif';
  }
  if (normalized.contains('webp')) {
    return '.webp';
  }
  if (normalized.contains('mp4')) {
    return '.mp4';
  }
  if (normalized.contains('quicktime') || normalized.contains('mov')) {
    return '.mov';
  }
  if (normalized.contains('webm')) {
    return '.webm';
  }
  if (normalized.contains('matroska') || normalized.contains('mkv')) {
    return '.mkv';
  }
  return '.bin';
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

String _replaceExtension(String fileName, String extension) {
  // Replace the original file extension with a derived one.
  // 将原始文件扩展名替换为派生扩展名。
  final baseName = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
  return '${baseName.isEmpty ? 'image' : baseName}$extension';
}

class _PreparedImage {
  _PreparedImage({
    required this.fileName,
    required this.mime,
    required this.bytes,
  });

  final String fileName;
  final String mime;
  final Uint8List bytes;
}
