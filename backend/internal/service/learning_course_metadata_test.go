package service

import (
	"errors"
	"testing"
)

func TestLearningCourseStatusDefaultsAndVisibility(t *testing.T) {
	// New lesson files start as draft for admins and remain hidden from regular learners until published.
	// 新课程文件默认以草稿状态创建，普通学习用户在发布前不可见。
	oldDir := markdownStorageDir
	t.Cleanup(func() {
		markdownStorageDir = oldDir
	})

	tempDir := t.TempDir()
	SetMarkdownStorageDir(tempDir)

	if _, _, err := SaveMarkdownFile("courses/test-course.zh-CN.md", "# Draft"); err != nil {
		t.Fatalf("save draft lesson: %v", err)
	}

	adminItems, err := ListMarkdownFilesForLevel("admin")
	if err != nil {
		t.Fatalf("list files for admin: %v", err)
	}
	if len(adminItems) != 1 || adminItems[0].Status != LearningCourseStatusDraft {
		t.Fatalf("expected one draft lesson for admin, got %#v", adminItems)
	}

	learnerItems, err := ListMarkdownFilesForLevel("basic")
	if err != nil {
		t.Fatalf("list files for learner: %v", err)
	}
	if len(learnerItems) != 0 {
		t.Fatalf("expected draft lesson to stay hidden from learner, got %#v", learnerItems)
	}

	if _, err := GetMarkdownFileForLevel("courses/test-course.zh-CN.md", "basic"); !errors.Is(err, ErrMarkdownFileNotFound) {
		t.Fatalf("expected hidden draft lesson to return not found, got %v", err)
	}

	if _, err := SetLearningCourseStatus("courses/test-course.zh-CN.md", LearningCourseStatusPublished); err != nil {
		t.Fatalf("publish lesson: %v", err)
	}

	publishedItems, err := ListMarkdownFilesForLevel("basic")
	if err != nil {
		t.Fatalf("list published files for learner: %v", err)
	}
	if len(publishedItems) != 1 || publishedItems[0].Status != LearningCourseStatusPublished {
		t.Fatalf("expected one published lesson for learner, got %#v", publishedItems)
	}
}
