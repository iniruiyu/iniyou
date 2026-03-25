package service

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"log"
	"mime"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
)

const defaultPostMediaStorageDir = "D:/codeX/iniyou/uploads/space-service"

var postMediaStorageDir = filepath.Clean(defaultPostMediaStorageDir)

type postMediaFileRef struct {
	// File reference used for physical cleanup on disk.
	// 用于磁盘物理清理的文件引用。
	PostID    string
	MediaName string
}

func SetPostMediaStorageDir(dir string) {
	// Set the root directory used to persist post media files.
	// 设置文章媒体文件的落盘根目录。
	dir = filepath.Clean(strings.TrimSpace(dir))
	if dir != "" && dir != "." {
		postMediaStorageDir = dir
	}
}

func currentPostMediaStorageDir() string {
	// Return the configured storage directory or the default fallback.
	// 返回已配置的存储目录，或使用默认回退路径。
	dir := filepath.Clean(strings.TrimSpace(postMediaStorageDir))
	if dir == "" || dir == "." {
		return filepath.Clean(defaultPostMediaStorageDir)
	}
	return dir
}

func newPostRecordID() string {
	// Generate a database-safe UUID post identifier for storage and file scoping.
	// 生成数据库安全的 UUID 文章标识，同时用于文件目录分层。
	return uuid.NewString()
}

func randomHexToken(byteLen int) string {
	// Generate a random hexadecimal token without introducing extra dependencies.
	// 生成随机十六进制 token，避免引入额外依赖。
	if byteLen <= 0 {
		byteLen = 16
	}
	buf := make([]byte, byteLen)
	if _, err := rand.Read(buf); err != nil {
		return fmt.Sprintf("%d%x", os.Getpid(), buf)
	}
	return hex.EncodeToString(buf)
}

func postMediaDir(postID string) string {
	// Scope each post's files to its own directory.
	// 将每篇文章的文件限制在独立目录中。
	return filepath.Join(currentPostMediaStorageDir(), "posts", sanitizePathSegment(postID))
}

func postMediaFilePath(postID string, mediaName string) string {
	// Build the absolute file path for a stored media asset.
	// 构建已存储媒体资源的绝对文件路径。
	return filepath.Join(postMediaDir(postID), sanitizePathSegment(mediaName))
}

func sanitizePathSegment(value string) string {
	// Keep only filesystem-safe characters for a single path segment.
	// 仅保留适合文件系统路径片段的安全字符。
	value = strings.TrimSpace(filepath.Base(value))
	if value == "" || value == "." || value == string(filepath.Separator) {
		return ""
	}
	var builder strings.Builder
	builder.Grow(len(value))
	for _, r := range value {
		switch {
		case r >= 'a' && r <= 'z':
			builder.WriteRune(r)
		case r >= 'A' && r <= 'Z':
			builder.WriteRune(r)
		case r >= '0' && r <= '9':
			builder.WriteRune(r)
		case r == '-', r == '_', r == '.':
			builder.WriteRune(r)
		}
	}
	return strings.Trim(builder.String(), ".")
}

func mediaFileExtension(mediaType string, mediaName string, mediaMime string) string {
	// Infer a stable extension from the current media metadata.
	// 根据现有媒体元数据推断稳定的扩展名。
	mediaName = strings.TrimSpace(mediaName)
	mediaMime = strings.TrimSpace(mediaMime)
	mediaType = strings.ToLower(strings.TrimSpace(mediaType))
	if ext := strings.ToLower(filepath.Ext(mediaName)); ext != "" {
		return ext
	}
	if mediaMime != "" {
		if extensions, err := mime.ExtensionsByType(mediaMime); err == nil && len(extensions) > 0 {
			return strings.ToLower(extensions[0])
		}
	}
	switch mediaType {
	case "image":
		return ".webp"
	case "video":
		return ".mp4"
	default:
		return ".bin"
	}
}

func buildStoredMediaName(item PostMediaItem) string {
	// Generate a random storage filename while preserving the media extension.
	// 生成随机存储文件名，同时保留媒体扩展名。
	return "media-" + randomHexToken(16) + mediaFileExtension(item.MediaType, item.MediaName, item.MediaMime)
}

func decodeBase64MediaPayload(mediaData string) ([]byte, error) {
	// Decode a raw base64 payload or a data URL payload into bytes.
	// 将原始 base64 载荷或 data URL 载荷解码为字节。
	payload := strings.TrimSpace(mediaData)
	if payload == "" {
		return nil, fmt.Errorf("media payload required")
	}
	if strings.HasPrefix(payload, "data:") {
		if comma := strings.IndexByte(payload, ','); comma >= 0 {
			payload = payload[comma+1:]
		}
	}
	return base64.StdEncoding.DecodeString(payload)
}

func samePostMediaPayload(a PostMediaItem, b PostMediaItem) bool {
	// Compare the logical media payload without caring about storage-only behavior.
	// 比较逻辑媒体载荷，不关注存储层实现细节。
	return strings.TrimSpace(a.MediaType) == strings.TrimSpace(b.MediaType) &&
		strings.TrimSpace(a.MediaMime) == strings.TrimSpace(b.MediaMime) &&
		strings.TrimSpace(a.MediaData) == strings.TrimSpace(b.MediaData)
}

func samePostMediaItems(a []PostMediaItem, b []PostMediaItem) bool {
	// Compare two ordered media galleries for an exact logical match.
	// 比较两个有序媒体集合是否完全一致。
	if len(a) != len(b) {
		return false
	}
	for idx := range a {
		left := a[idx]
		right := b[idx]
		if sanitizePathSegment(left.MediaName) != sanitizePathSegment(right.MediaName) {
			return false
		}
		if !samePostMediaPayload(left, right) {
			return false
		}
	}
	return true
}

func fileExists(path string) bool {
	// Check whether a file is already present on disk.
	// 检查文件是否已经落盘存在。
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func postMediaFilesExist(postID string, items []PostMediaItem) bool {
	// Check that every media item still has a corresponding on-disk file.
	// 检查每个媒体项是否都仍然对应着磁盘文件。
	postID = strings.TrimSpace(postID)
	if postID == "" {
		return false
	}
	for _, item := range items {
		mediaName := sanitizePathSegment(item.MediaName)
		if mediaName == "" {
			return false
		}
		if !fileExists(postMediaFilePath(postID, mediaName)) {
			return false
		}
	}
	return true
}

func persistPostMediaItems(postID string, items []PostMediaItem, existingItems []PostMediaItem) ([]PostMediaItem, []postMediaFileRef, error) {
	// Persist the current media gallery to disk and keep stable names when possible.
	// 将当前媒体集合落盘，并在可行时保持文件名稳定。
	postID = strings.TrimSpace(postID)
	if postID == "" {
		return nil, nil, fmt.Errorf("post id required")
	}
	normalized := make([]PostMediaItem, 0, len(items))
	existingByName := make(map[string]PostMediaItem, len(existingItems))
	for _, item := range existingItems {
		name := sanitizePathSegment(item.MediaName)
		if name == "" {
			continue
		}
		existingByName[name] = item
	}

	seenNames := make(map[string]struct{}, len(items))
	writtenRefs := make([]postMediaFileRef, 0, len(items))
	for _, rawItem := range items {
		item := normalizePostMediaItem(rawItem.MediaType, rawItem.MediaName, rawItem.MediaMime, rawItem.MediaData)
		if item.MediaData == "" {
			continue
		}

		storageName := sanitizePathSegment(item.MediaName)
		if storageName != "" {
			if existing, ok := existingByName[storageName]; ok && samePostMediaPayload(existing, item) {
				absolutePath := postMediaFilePath(postID, storageName)
				if fileExists(absolutePath) {
					if _, used := seenNames[storageName]; !used {
						item.MediaName = storageName
						normalized = append(normalized, item)
						seenNames[storageName] = struct{}{}
						continue
					}
				}
			}
		}

		storageName = buildStoredMediaName(item)
		for {
			if _, used := seenNames[storageName]; !used {
				break
			}
			storageName = buildStoredMediaName(item)
		}
		absolutePath := postMediaFilePath(postID, storageName)
		if err := os.MkdirAll(filepath.Dir(absolutePath), 0o755); err != nil {
			cleanupPostMediaFiles(writtenRefs, false)
			return nil, nil, err
		}
		data, err := decodeBase64MediaPayload(item.MediaData)
		if err != nil {
			cleanupPostMediaFiles(writtenRefs, false)
			return nil, nil, err
		}
		if err := os.WriteFile(absolutePath, data, 0o644); err != nil {
			cleanupPostMediaFiles(writtenRefs, false)
			return nil, nil, err
		}
		item.MediaName = storageName
		normalized = append(normalized, item)
		seenNames[storageName] = struct{}{}
		writtenRefs = append(writtenRefs, postMediaFileRef{PostID: postID, MediaName: storageName})
	}

	return normalized, writtenRefs, nil
}

func cleanupPostMediaFiles(refs []postMediaFileRef, removeDirectories bool) {
	// Remove media files from disk and optionally remove their post directory.
	// 从磁盘移除媒体文件，并可选删除对应文章目录。
	if len(refs) == 0 {
		return
	}
	if removeDirectories {
		seenPosts := make(map[string]struct{}, len(refs))
		for _, ref := range refs {
			postID := strings.TrimSpace(ref.PostID)
			if postID == "" {
				continue
			}
			if _, ok := seenPosts[postID]; ok {
				continue
			}
			seenPosts[postID] = struct{}{}
			if err := os.RemoveAll(postMediaDir(postID)); err != nil && !os.IsNotExist(err) {
				log.Printf("post media directory cleanup failed: post_id=%s err=%v", postID, err)
			}
		}
		return
	}

	for _, ref := range refs {
		postID := strings.TrimSpace(ref.PostID)
		mediaName := sanitizePathSegment(ref.MediaName)
		if postID == "" || mediaName == "" {
			continue
		}
		filePath := postMediaFilePath(postID, mediaName)
		if err := os.Remove(filePath); err != nil && !os.IsNotExist(err) {
			log.Printf("post media file cleanup failed: post_id=%s media_name=%s err=%v", postID, mediaName, err)
		}
	}
}

func collectPostMediaRefs(postID string, items []PostMediaItem) []postMediaFileRef {
	// Build cleanup references for a post's current media items.
	// 为文章的当前媒体项构建清理引用。
	postID = strings.TrimSpace(postID)
	if postID == "" || len(items) == 0 {
		return nil
	}
	refs := make([]postMediaFileRef, 0, len(items))
	for _, item := range items {
		mediaName := sanitizePathSegment(item.MediaName)
		if mediaName == "" {
			continue
		}
		refs = append(refs, postMediaFileRef{PostID: postID, MediaName: mediaName})
	}
	return refs
}

func diffRemovedPostMediaRefs(postID string, existingItems []PostMediaItem, finalItems []PostMediaItem) []postMediaFileRef {
	// Collect media references that disappeared from an updated post.
	// 收集在文章更新后被移除的媒体引用。
	postID = strings.TrimSpace(postID)
	if postID == "" || len(existingItems) == 0 {
		return nil
	}
	finalNames := make(map[string]struct{}, len(finalItems))
	for _, item := range finalItems {
		name := sanitizePathSegment(item.MediaName)
		if name == "" {
			continue
		}
		finalNames[name] = struct{}{}
	}
	refs := make([]postMediaFileRef, 0, len(existingItems))
	for _, item := range existingItems {
		mediaName := sanitizePathSegment(item.MediaName)
		if mediaName == "" {
			continue
		}
		if _, ok := finalNames[mediaName]; ok {
			continue
		}
		refs = append(refs, postMediaFileRef{PostID: postID, MediaName: mediaName})
	}
	return refs
}
