// Web-only post media picker; dart:html is used here for the browser file dialog.
// Web 端帖子媒体选择器；这里使用 dart:html 触发浏览器文件选择框。
// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../models/app_models.dart';

// Cap article image uploads on the longest edge so previews stay manageable.
// 将文章图片上传的最长边限制住，避免预览和传输体积过大。
const int _maxImageDimension = 1600;

Future<PostAttachmentDraft?> pickPostAttachment(String mediaType) async {
  // Let the browser pick an image or short video and keep its raw bytes.
  // 让浏览器选择图片或小视频，并保留其原始字节。
  final input = html.FileUploadInputElement()
    ..accept = _acceptFor(mediaType)
    ..multiple = false;
  html.document.body?.append(input);
  try {
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

    final bytes = _readBytesFromReader(reader.result);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final mime = file.type.isNotEmpty
        ? file.type
        : _mimeFor(mediaType, file.name);
    final normalizedType = _normalizeMediaType(mediaType, mime, file.name);
    if (normalizedType == 'image') {
      final prepared = await _prepareImageUpload(
        bytes: bytes,
        mime: mime,
        fileName: file.name,
      );
      if (prepared != null) {
        return PostAttachmentDraft(
          mediaType: 'image',
          mediaName: prepared.fileName,
          mediaMime: prepared.mime,
          mediaData: prepared.base64Data,
          originalSizeBytes: bytes.length,
        );
      }
    }
    return PostAttachmentDraft(
      mediaType: normalizedType,
      mediaName: file.name,
      mediaMime: mime,
      mediaData: base64Encode(bytes),
      originalSizeBytes: bytes.length,
    );
  } finally {
    input.remove();
  }
}

Uint8List? _readBytesFromReader(Object? result) {
  // Accept the web file reader result in multiple runtime shapes.
  // 兼容 web 文件读取结果在运行时的多种类型。
  if (result is ByteBuffer) {
    return Uint8List.view(result);
  }
  if (result is Uint8List) {
    return result;
  }
  if (result is List<int>) {
    return Uint8List.fromList(result);
  }
  return null;
}

Future<_PreparedImage?> _prepareImageUpload({
  required Uint8List bytes,
  required String mime,
  required String fileName,
}) async {
  // Resize images proportionally before upload so oversized photos stay bounded.
  // 上传前按比例缩放图片，避免超大照片占用过多空间。
  try {
    final sourceMime = mime.isNotEmpty ? mime : 'image/png';
    final sourceUrl = Uri.dataFromBytes(bytes, mimeType: sourceMime).toString();
    final image = html.ImageElement();
    final loaded = image.onLoad.first;
    image.src = sourceUrl;
    await loaded;

    final width = image.naturalWidth;
    final height = image.naturalHeight;
    if (width <= 0 || height <= 0) {
      return null;
    }
    if (width <= _maxImageDimension && height <= _maxImageDimension) {
      return null;
    }

    final target = _scaleToFit(width, height);
    final canvas = html.CanvasElement(
      width: target.width,
      height: target.height,
    );
    canvas.context2D.drawImageScaled(image, 0, 0, target.width, target.height);

    final encoded = _encodeCanvas(canvas);
    if (encoded == null) {
      return null;
    }

    return _PreparedImage(
      fileName: _replaceExtension(fileName, encoded.extension),
      mime: encoded.mime,
      base64Data: encoded.base64Data,
    );
  } catch (_) {
    return null;
  }
}

_CanvasEncoding? _encodeCanvas(html.CanvasElement canvas) {
  // Prefer WebP when the browser can export it, then fall back to PNG.
  // 优先使用浏览器可导出的 WebP，不支持时回退到 PNG。
  for (final encoding in const [
    _CanvasEncoding(mime: 'image/webp', extension: '.webp', base64Data: ''),
    _CanvasEncoding(mime: 'image/png', extension: '.png', base64Data: ''),
  ]) {
    try {
      final dataUrl = canvas.toDataUrl(encoding.mime, 0.92);
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex < 0) {
        continue;
      }
      return _CanvasEncoding(
        mime: encoding.mime,
        extension: encoding.extension,
        base64Data: dataUrl.substring(commaIndex + 1),
      );
    } catch (_) {
      // Try the next encoding option.
      // 尝试下一个编码格式。
    }
  }
  return null;
}

({int width, int height}) _scaleToFit(int width, int height) {
  // Keep the original aspect ratio while constraining the longest side.
  // 保持原始宽高比，同时限制最长边尺寸。
  if (width <= _maxImageDimension && height <= _maxImageDimension) {
    return (width: width, height: height);
  }
  final widthRatio = _maxImageDimension / width;
  final heightRatio = _maxImageDimension / height;
  final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;
  final scaledWidth = (width * ratio).round();
  final scaledHeight = (height * ratio).round();
  return (
    width: scaledWidth < 1 ? 1 : scaledWidth,
    height: scaledHeight < 1 ? 1 : scaledHeight,
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
    required this.base64Data,
  });

  final String fileName;
  final String mime;
  final String base64Data;
}

class _CanvasEncoding {
  const _CanvasEncoding({
    required this.mime,
    required this.extension,
    required this.base64Data,
  });

  final String mime;
  final String extension;
  final String base64Data;
}
