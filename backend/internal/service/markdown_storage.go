package service

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const defaultMarkdownStorageDir = "D:/codeX/iniyou/uploads/learning-service/markdown-files"

var markdownStorageDir = filepath.Clean(defaultMarkdownStorageDir)

var (
	// ErrInvalidMarkdownPath rejects invalid, unsafe, or non-Markdown file paths.
	// ErrInvalidMarkdownPath 用于拒绝无效、不安全或非 Markdown 的文件路径。
	ErrInvalidMarkdownPath = errors.New("invalid markdown path")
	// ErrMarkdownFileNotFound signals a missing markdown document on disk.
	// ErrMarkdownFileNotFound 用于表示磁盘上的 Markdown 文档不存在。
	ErrMarkdownFileNotFound = errors.New("markdown file not found")
)

type MarkdownFileSummary struct {
	// Path is the normalized relative path inside the markdown storage root.
	// Path 是 Markdown 存储根目录下的规范化相对路径。
	Path string `json:"path"`
	// Size reports the persisted file size in bytes.
	// Size 表示已落盘文件的字节大小。
	Size int64 `json:"size"`
	// UpdatedAt keeps the last modification time for listing and cache checks.
	// UpdatedAt 保存最后修改时间，便于列表展示与缓存判断。
	UpdatedAt time.Time `json:"updated_at"`
}

type MarkdownFileDocument struct {
	// Path is the normalized relative path used by API callers.
	// Path 是 API 调用方使用的规范化相对路径。
	Path string `json:"path"`
	// Content stores the UTF-8 markdown source text.
	// Content 保存 UTF-8 Markdown 源文本。
	Content string `json:"content"`
	// Size reports the persisted file size in bytes.
	// Size 表示已落盘文件的字节大小。
	Size int64 `json:"size"`
	// UpdatedAt keeps the last modification time for the document.
	// UpdatedAt 保存文档最后修改时间。
	UpdatedAt time.Time `json:"updated_at"`
}

func SetMarkdownStorageDir(dir string) {
	// Set the root directory used to persist markdown course files.
	// 设置 Markdown 课程文件的落盘根目录。
	dir = filepath.Clean(strings.TrimSpace(dir))
	if dir != "" && dir != "." {
		markdownStorageDir = dir
	}
}

func currentMarkdownStorageDir() string {
	// Return the configured markdown root or the default fallback directory.
	// 返回已配置的 Markdown 根目录，或默认回退目录。
	dir := filepath.Clean(strings.TrimSpace(markdownStorageDir))
	if dir == "" || dir == "." {
		return filepath.Clean(defaultMarkdownStorageDir)
	}
	return dir
}

func ListMarkdownFiles() ([]MarkdownFileSummary, error) {
	// Enumerate all stored markdown files beneath the configured root.
	// 枚举配置根目录下的全部 Markdown 文件。
	root := currentMarkdownStorageDir()
	if err := os.MkdirAll(root, 0o755); err != nil {
		return nil, err
	}

	items := make([]MarkdownFileSummary, 0, 16)
	err := filepath.WalkDir(root, func(filePath string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() {
			return nil
		}
		if !strings.EqualFold(filepath.Ext(entry.Name()), ".md") {
			return nil
		}

		info, err := entry.Info()
		if err != nil {
			return err
		}
		relativePath, err := filepath.Rel(root, filePath)
		if err != nil {
			return err
		}

		items = append(items, MarkdownFileSummary{
			Path:      filepath.ToSlash(relativePath),
			Size:      info.Size(),
			UpdatedAt: info.ModTime(),
		})
		return nil
	})
	if err != nil {
		return nil, err
	}

	sort.Slice(items, func(left int, right int) bool {
		if items[left].UpdatedAt.Equal(items[right].UpdatedAt) {
			return items[left].Path < items[right].Path
		}
		return items[left].UpdatedAt.After(items[right].UpdatedAt)
	})
	return items, nil
}

func GetMarkdownFile(relativePath string) (MarkdownFileDocument, error) {
	// Read a single markdown file from disk using a normalized relative path.
	// 使用规范化相对路径从磁盘读取单个 Markdown 文件。
	normalizedPath, absolutePath, err := markdownFileAbsolutePath(relativePath)
	if err != nil {
		return MarkdownFileDocument{}, err
	}

	info, err := os.Stat(absolutePath)
	if err != nil {
		if os.IsNotExist(err) {
			return MarkdownFileDocument{}, ErrMarkdownFileNotFound
		}
		return MarkdownFileDocument{}, err
	}
	if info.IsDir() {
		return MarkdownFileDocument{}, ErrInvalidMarkdownPath
	}

	content, err := os.ReadFile(absolutePath)
	if err != nil {
		return MarkdownFileDocument{}, err
	}

	return MarkdownFileDocument{
		Path:      normalizedPath,
		Content:   string(content),
		Size:      info.Size(),
		UpdatedAt: info.ModTime(),
	}, nil
}

func SaveMarkdownFile(relativePath string, content string) (MarkdownFileDocument, bool, error) {
	// Create or replace a markdown file beneath the configured storage root.
	// 在配置的存储根目录下创建或覆盖 Markdown 文件。
	normalizedPath, absolutePath, err := markdownFileAbsolutePath(relativePath)
	if err != nil {
		return MarkdownFileDocument{}, false, err
	}

	created := !fileExists(absolutePath)
	if err := os.MkdirAll(filepath.Dir(absolutePath), 0o755); err != nil {
		return MarkdownFileDocument{}, false, err
	}
	if err := os.WriteFile(absolutePath, []byte(content), 0o644); err != nil {
		return MarkdownFileDocument{}, false, err
	}

	document, err := GetMarkdownFile(normalizedPath)
	if err != nil {
		return MarkdownFileDocument{}, false, err
	}
	return document, created, nil
}

func DeleteMarkdownFile(relativePath string) error {
	// Delete one markdown file beneath the configured storage root and ignore duplicate deletes.
	// 删除配置存储根目录下的单个 Markdown 文件，并对重复删除保持幂等。
	_, absolutePath, err := markdownFileAbsolutePath(relativePath)
	if err != nil {
		return err
	}
	if err := os.Remove(absolutePath); err != nil {
		if os.IsNotExist(err) {
			return ErrMarkdownFileNotFound
		}
		return err
	}
	return nil
}

func markdownFileAbsolutePath(relativePath string) (string, string, error) {
	// Normalize the relative path and join it to the storage root safely.
	// 规范化相对路径，并安全地拼接到存储根目录。
	normalizedPath, err := normalizeMarkdownRelativePath(relativePath)
	if err != nil {
		return "", "", err
	}
	return normalizedPath, filepath.Join(currentMarkdownStorageDir(), filepath.FromSlash(normalizedPath)), nil
}

func normalizeMarkdownRelativePath(rawPath string) (string, error) {
	// Accept only safe nested .md paths and reject traversal attempts.
	// 仅接受安全的多级 .md 路径，并拒绝目录穿越。
	trimmed := strings.TrimSpace(strings.ReplaceAll(rawPath, "\\", "/"))
	trimmed = strings.TrimPrefix(trimmed, "/")
	if trimmed == "" {
		return "", ErrInvalidMarkdownPath
	}
	for _, segment := range strings.Split(trimmed, "/") {
		if segment == "." || segment == ".." {
			return "", ErrInvalidMarkdownPath
		}
	}

	cleaned := path.Clean(trimmed)
	if cleaned == "." || cleaned == "" || cleaned == ".." || strings.HasPrefix(cleaned, "../") {
		return "", ErrInvalidMarkdownPath
	}
	if !strings.EqualFold(path.Ext(cleaned), ".md") {
		return "", ErrInvalidMarkdownPath
	}

	segments := strings.Split(cleaned, "/")
	validSegments := make([]string, 0, len(segments))
	for _, segment := range segments {
		normalizedSegment, err := normalizeMarkdownPathSegment(segment)
		if err != nil {
			return "", err
		}
		validSegments = append(validSegments, normalizedSegment)
	}

	return strings.Join(validSegments, "/"), nil
}

func normalizeMarkdownPathSegment(segment string) (string, error) {
	// Allow only filesystem-safe path segments without mutating caller intent.
	// 仅允许文件系统安全的路径片段，且不静默改写调用方语义。
	segment = strings.TrimSpace(segment)
	if segment == "" || segment == "." || segment == ".." {
		return "", ErrInvalidMarkdownPath
	}

	var builder strings.Builder
	builder.Grow(len(segment))
	for _, r := range segment {
		switch {
		case r >= 'a' && r <= 'z':
			builder.WriteRune(r)
		case r >= 'A' && r <= 'Z':
			builder.WriteRune(r)
		case r >= '0' && r <= '9':
			builder.WriteRune(r)
		case r == '-', r == '_', r == '.':
			builder.WriteRune(r)
		default:
			return "", fmt.Errorf("%w: %s", ErrInvalidMarkdownPath, segment)
		}
	}

	normalized := builder.String()
	if normalized == "" || strings.HasPrefix(normalized, ".") {
		return "", ErrInvalidMarkdownPath
	}
	return normalized, nil
}
