package service

import (
	"encoding/base64"
	"os"
	"path/filepath"
	"testing"

	"github.com/google/uuid"
)

func TestPersistPostMediaItemsWritesAndCleansUp(t *testing.T) {
	// Persist one attachment, then verify the file is written and removed.
	// 落盘一个附件，再验证文件已写入并能被清理。
	oldDir := postMediaStorageDir
	t.Cleanup(func() {
		postMediaStorageDir = oldDir
	})

	tempDir := t.TempDir()
	SetPostMediaStorageDir(tempDir)

	payload := []byte("post-media-payload")
	item := PostMediaItem{
		MediaType: "image",
		MediaName: "photo.png",
		MediaMime: "image/png",
		MediaData: base64.StdEncoding.EncodeToString(payload),
	}

	persisted, refs, err := persistPostMediaItems("post-test", []PostMediaItem{item}, nil)
	if err != nil {
		t.Fatalf("persist media items: %v", err)
	}
	if len(persisted) != 1 {
		t.Fatalf("expected 1 persisted item, got %d", len(persisted))
	}
	if len(refs) != 1 {
		t.Fatalf("expected 1 cleanup ref, got %d", len(refs))
	}
	if persisted[0].MediaName == item.MediaName {
		t.Fatalf("expected a randomized storage filename, got %q", persisted[0].MediaName)
	}

	storedPath := postMediaFilePath("post-test", persisted[0].MediaName)
	data, err := os.ReadFile(storedPath)
	if err != nil {
		t.Fatalf("read stored file: %v", err)
	}
	if string(data) != string(payload) {
		t.Fatalf("unexpected stored payload: %q", string(data))
	}

	cleanupPostMediaFiles(refs, true)
	if _, err := os.Stat(filepath.Join(tempDir, "posts", "post-test")); !os.IsNotExist(err) {
		t.Fatalf("expected post media directory to be removed, got err=%v", err)
	}
}

func TestPersistPostMediaItemsReusesStableNameWhenFileExists(t *testing.T) {
	// Reuse the same media payload and storage name when the file already exists.
	// 当文件已存在且载荷未变时，复用同一个存储文件名。
	oldDir := postMediaStorageDir
	t.Cleanup(func() {
		postMediaStorageDir = oldDir
	})

	tempDir := t.TempDir()
	SetPostMediaStorageDir(tempDir)

	payload := []byte("post-media-payload")
	item := PostMediaItem{
		MediaType: "image",
		MediaName: "photo.png",
		MediaMime: "image/png",
		MediaData: base64.StdEncoding.EncodeToString(payload),
	}

	persisted, refs, err := persistPostMediaItems("post-test", []PostMediaItem{item}, nil)
	if err != nil {
		t.Fatalf("persist initial media items: %v", err)
	}

	reused, newRefs, err := persistPostMediaItems("post-test", []PostMediaItem{persisted[0]}, persisted)
	if err != nil {
		t.Fatalf("persist reused media items: %v", err)
	}
	if len(newRefs) != 0 {
		t.Fatalf("expected no new files, got %d refs", len(newRefs))
	}
	if len(reused) != 1 {
		t.Fatalf("expected 1 reused item, got %d", len(reused))
	}
	if reused[0].MediaName != persisted[0].MediaName {
		t.Fatalf("expected storage filename reuse, got %q and %q", persisted[0].MediaName, reused[0].MediaName)
	}

	cleanupPostMediaFiles(refs, true)
}

func TestNewPostRecordIDReturnsUUID(t *testing.T) {
	// Ensure post IDs remain valid UUIDs for PostgreSQL UUID columns.
	// 确保文章 ID 始终是合法 UUID，兼容 PostgreSQL 的 UUID 列。
	id := newPostRecordID()
	if _, err := uuid.Parse(id); err != nil {
		t.Fatalf("expected UUID post id, got %q: %v", id, err)
	}
}
