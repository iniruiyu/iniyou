package service

import (
	"errors"
	"strings"
	"testing"
)

func TestSaveMarkdownFileAndListMarkdownFiles(t *testing.T) {
	// Save markdown documents, then verify they can be listed and read back.
	// 保存 Markdown 文档，再验证可以列出并回读。
	oldDir := markdownStorageDir
	t.Cleanup(func() {
		markdownStorageDir = oldDir
	})

	tempDir := t.TempDir()
	SetMarkdownStorageDir(tempDir)

	firstDocument, created, err := SaveMarkdownFile("learning/english/welcome.md", "# Hello\n\n- item")
	if err != nil {
		t.Fatalf("save first markdown file: %v", err)
	}
	if !created {
		t.Fatalf("expected the first save to create a new file")
	}
	if firstDocument.Path != "learning/english/welcome.md" {
		t.Fatalf("unexpected first path: %q", firstDocument.Path)
	}
	if firstDocument.Content != "# Hello\n\n- item" {
		t.Fatalf("unexpected first content: %q", firstDocument.Content)
	}

	secondDocument, created, err := SaveMarkdownFile("learning/programming/intro.md", "```go\nfmt.Println(\"hi\")\n```")
	if err != nil {
		t.Fatalf("save second markdown file: %v", err)
	}
	if !created {
		t.Fatalf("expected the second save to create a new file")
	}
	if secondDocument.Path != "learning/programming/intro.md" {
		t.Fatalf("unexpected second path: %q", secondDocument.Path)
	}

	updatedDocument, created, err := SaveMarkdownFile("learning/english/welcome.md", "# Updated")
	if err != nil {
		t.Fatalf("update markdown file: %v", err)
	}
	if created {
		t.Fatalf("expected the second save of the same file to be an update")
	}
	if updatedDocument.Content != "# Updated" {
		t.Fatalf("unexpected updated content: %q", updatedDocument.Content)
	}

	files, err := ListMarkdownFiles()
	if err != nil {
		t.Fatalf("list markdown files: %v", err)
	}
	if len(files) != 2 {
		t.Fatalf("expected 2 markdown files, got %d", len(files))
	}

	loadedDocument, err := GetMarkdownFile("learning/english/welcome.md")
	if err != nil {
		t.Fatalf("get markdown file: %v", err)
	}
	if loadedDocument.Content != "# Updated" {
		t.Fatalf("unexpected loaded content: %q", loadedDocument.Content)
	}
}

func TestNormalizeMarkdownRelativePathRejectsUnsafePaths(t *testing.T) {
	// Reject traversal, unsupported extensions, and unsafe characters.
	// 拒绝目录穿越、不支持的扩展名和不安全字符。
	invalidPaths := []string{
		"",
		"../secret.md",
		"/../secret.md",
		"learning/../secret.md",
		"learning/course.txt",
		"learning/course",
		"learning/course name.md",
		".hidden.md",
	}

	for _, invalidPath := range invalidPaths {
		_, err := normalizeMarkdownRelativePath(invalidPath)
		if !errors.Is(err, ErrInvalidMarkdownPath) {
			t.Fatalf("expected invalid markdown path for %q, got %v", invalidPath, err)
		}
	}
}

func TestGetMarkdownFileReturnsNotFound(t *testing.T) {
	// Surface a stable not-found error for missing markdown documents.
	// 对缺失的 Markdown 文档返回稳定的 not-found 错误。
	oldDir := markdownStorageDir
	t.Cleanup(func() {
		markdownStorageDir = oldDir
	})

	tempDir := t.TempDir()
	SetMarkdownStorageDir(tempDir)

	_, err := GetMarkdownFile("learning/missing.md")
	if !errors.Is(err, ErrMarkdownFileNotFound) {
		t.Fatalf("expected markdown not found error, got %v", err)
	}

	normalized, err := normalizeMarkdownRelativePath("\\learning\\ai\\mindmap.md")
	if err != nil {
		t.Fatalf("normalize windows-like markdown path: %v", err)
	}
	if !strings.Contains(normalized, "learning/ai/mindmap.md") {
		t.Fatalf("unexpected normalized path: %q", normalized)
	}
}
