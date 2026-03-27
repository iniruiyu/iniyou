package service

import (
	"embed"
	"io/fs"
	"path/filepath"
	"strings"
)

// embeddedLearningSeedFiles keeps the default markdown lessons packaged with the learning service.
// embeddedLearningSeedFiles 保存随学习服务一起打包的默认 Markdown 课程文件。
//
//go:embed learning_seed/*.md
var embeddedLearningSeedFiles embed.FS

func EnsureDefaultLearningMarkdownFiles() error {
	// Seed the default learning markdown files only when the target path is still missing.
	// 仅在目标路径尚不存在时写入默认学习 Markdown 文件。
	entries, err := fs.ReadDir(embeddedLearningSeedFiles, "learning_seed")
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if entry.IsDir() || !strings.EqualFold(filepath.Ext(entry.Name()), ".md") {
			continue
		}
		assetPath := filepath.ToSlash(filepath.Join("learning_seed", entry.Name()))
		relativePath := filepath.ToSlash(filepath.Join("courses", entry.Name()))
		if err := seedMarkdownFileIfMissing(relativePath, assetPath); err != nil {
			return err
		}
	}
	return nil
}

func seedMarkdownFileIfMissing(relativePath string, assetPath string) error {
	// Write one embedded markdown asset only if the destination file is absent.
	// 仅当目标文件不存在时写入单个内嵌 Markdown 资源。
	_, absolutePath, err := markdownFileAbsolutePath(relativePath)
	if err != nil {
		return err
	}
	if fileExists(absolutePath) {
		return nil
	}
	content, err := embeddedLearningSeedFiles.ReadFile(assetPath)
	if err != nil {
		return err
	}
	_, _, err = SaveMarkdownFile(relativePath, string(content))
	return err
}
