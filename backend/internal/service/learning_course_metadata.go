package service

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

const (
	LearningCourseStatusDraft     = "draft"
	LearningCourseStatusPublished = "published"
	LearningCourseStatusArchived  = "archived"
)

var (
	// ErrInvalidLearningCourseStatus rejects unknown course status values.
	// ErrInvalidLearningCourseStatus 用于拒绝未知课程状态值。
	ErrInvalidLearningCourseStatus = errors.New("invalid learning course status")
	learningCourseMetadataMu       sync.Mutex
)

type learningCourseMetadataEntry struct {
	// Path keeps the normalized markdown path that this metadata row belongs to.
	// Path 保存该元数据记录对应的规范化 Markdown 路径。
	Path string `json:"path"`
	// CourseID is the derived logical course identifier.
	// CourseID 是推导出的逻辑课程标识。
	CourseID string `json:"course_id"`
	// Locale stores the derived locale segment from the markdown file name.
	// Locale 保存从 Markdown 文件名推导出的语言版本。
	Locale string `json:"locale"`
	// Status controls whether the lesson file is visible to regular learners.
	// Status 控制课程文件是否对普通学习用户可见。
	Status string `json:"status"`
	// UpdatedAt records the latest metadata mutation time.
	// UpdatedAt 记录最近一次元数据变更时间。
	UpdatedAt time.Time `json:"updated_at"`
}

type learningCourseMetadataStore struct {
	// Items holds metadata entries keyed by normalized markdown path.
	// Items 保存按规范化 Markdown 路径索引的元数据记录。
	Items map[string]learningCourseMetadataEntry `json:"items"`
}

func learningCourseMetadataFilePath() string {
	// Keep course metadata in one sidecar JSON file next to the markdown storage root.
	// 将课程元数据保存在 Markdown 存储根目录旁的单个 JSON 附属文件中。
	return filepath.Join(currentMarkdownStorageDir(), ".learning-course-metadata.json")
}

func ListMarkdownFilesForLevel(userLevel string) ([]MarkdownFileSummary, error) {
	// Enumerate markdown files and filter non-published lessons for non-admin viewers.
	// 枚举 Markdown 文件，并为非管理员过滤掉未发布课程。
	includeAllStatuses := IsAdminLevel(userLevel)
	items, err := ListMarkdownFiles()
	if err != nil {
		return nil, err
	}

	metadata, err := loadLearningCourseMetadata()
	if err != nil {
		return nil, err
	}

	filtered := make([]MarkdownFileSummary, 0, len(items))
	for _, item := range items {
		item.Status = learningCourseStatusForPath(metadata, item.Path)
		if !includeAllStatuses && !canAccessLearningMarkdownPath(item.Path, item.Status) {
			continue
		}
		filtered = append(filtered, item)
	}
	return filtered, nil
}

func GetMarkdownFileForLevel(relativePath string, userLevel string) (MarkdownFileDocument, error) {
	// Read one markdown file and hide non-published lesson content from non-admin viewers.
	// 读取单个 Markdown 文件，并对非管理员隐藏未发布课程内容。
	document, err := GetMarkdownFile(relativePath)
	if err != nil {
		return MarkdownFileDocument{}, err
	}

	metadata, err := loadLearningCourseMetadata()
	if err != nil {
		return MarkdownFileDocument{}, err
	}

	document.Status = learningCourseStatusForPath(metadata, document.Path)
	if !IsAdminLevel(userLevel) && !canAccessLearningMarkdownPath(document.Path, document.Status) {
		return MarkdownFileDocument{}, ErrMarkdownFileNotFound
	}
	return document, nil
}

func SetLearningCourseStatus(relativePath string, status string) (learningCourseMetadataEntry, error) {
	// Update the stored status for one lesson file and keep the metadata sidecar in sync.
	// 更新单个课程文件的状态，并保持元数据附属文件同步。
	normalizedPath, absolutePath, err := markdownFileAbsolutePath(relativePath)
	if err != nil {
		return learningCourseMetadataEntry{}, err
	}
	if !fileExists(absolutePath) {
		return learningCourseMetadataEntry{}, ErrMarkdownFileNotFound
	}
	status, err = normalizeLearningCourseStatus(status)
	if err != nil {
		return learningCourseMetadataEntry{}, err
	}

	descriptor, ok := parseLearningCourseDescriptor(normalizedPath)
	if !ok {
		return learningCourseMetadataEntry{}, ErrInvalidMarkdownPath
	}

	learningCourseMetadataMu.Lock()
	defer learningCourseMetadataMu.Unlock()

	store, err := loadLearningCourseMetadataUnlocked()
	if err != nil {
		return learningCourseMetadataEntry{}, err
	}
	entry := learningCourseMetadataEntry{
		Path:      normalizedPath,
		CourseID:  descriptor.CourseID,
		Locale:    descriptor.Locale,
		Status:    status,
		UpdatedAt: time.Now().UTC(),
	}
	store.Items[normalizedPath] = entry
	if err := saveLearningCourseMetadataUnlocked(store); err != nil {
		return learningCourseMetadataEntry{}, err
	}
	return entry, nil
}

func EnsureLearningCourseStatusIfMissing(relativePath string, defaultStatus string) error {
	// Seed a default lesson status only when the metadata row has not been created yet.
	// 仅在元数据记录尚不存在时写入默认课程状态。
	normalizedPath, _, err := markdownFileAbsolutePath(relativePath)
	if err != nil {
		return err
	}

	descriptor, ok := parseLearningCourseDescriptor(normalizedPath)
	if !ok {
		return nil
	}
	defaultStatus, err = normalizeLearningCourseStatus(defaultStatus)
	if err != nil {
		return err
	}

	learningCourseMetadataMu.Lock()
	defer learningCourseMetadataMu.Unlock()

	store, err := loadLearningCourseMetadataUnlocked()
	if err != nil {
		return err
	}
	if _, exists := store.Items[normalizedPath]; exists {
		return nil
	}
	store.Items[normalizedPath] = learningCourseMetadataEntry{
		Path:      normalizedPath,
		CourseID:  descriptor.CourseID,
		Locale:    descriptor.Locale,
		Status:    defaultStatus,
		UpdatedAt: time.Now().UTC(),
	}
	return saveLearningCourseMetadataUnlocked(store)
}

func DeleteLearningCourseMetadata(relativePath string) error {
	// Remove one lesson metadata record when its backing markdown file is deleted.
	// 在底层 Markdown 文件被删除时移除对应课程元数据记录。
	normalizedPath, _, err := markdownFileAbsolutePath(relativePath)
	if err != nil {
		return err
	}

	learningCourseMetadataMu.Lock()
	defer learningCourseMetadataMu.Unlock()

	store, err := loadLearningCourseMetadataUnlocked()
	if err != nil {
		return err
	}
	if _, exists := store.Items[normalizedPath]; !exists {
		return nil
	}
	delete(store.Items, normalizedPath)
	return saveLearningCourseMetadataUnlocked(store)
}

func loadLearningCourseMetadata() (learningCourseMetadataStore, error) {
	// Read the lesson metadata sidecar with a process-local lock to avoid torn writes.
	// 通过进程内锁读取课程元数据附属文件，避免出现撕裂写入。
	learningCourseMetadataMu.Lock()
	defer learningCourseMetadataMu.Unlock()
	return loadLearningCourseMetadataUnlocked()
}

func loadLearningCourseMetadataUnlocked() (learningCourseMetadataStore, error) {
	// Load the lesson metadata sidecar without acquiring the outer mutex.
	// 在不获取外层互斥锁的情况下加载课程元数据附属文件。
	path := learningCourseMetadataFilePath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return learningCourseMetadataStore{}, err
	}
	content, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return learningCourseMetadataStore{
				Items: map[string]learningCourseMetadataEntry{},
			}, nil
		}
		return learningCourseMetadataStore{}, err
	}
	var store learningCourseMetadataStore
	if err := json.Unmarshal(content, &store); err != nil {
		return learningCourseMetadataStore{}, err
	}
	if store.Items == nil {
		store.Items = map[string]learningCourseMetadataEntry{}
	}
	return store, nil
}

func saveLearningCourseMetadataUnlocked(store learningCourseMetadataStore) error {
	// Persist the full lesson metadata store atomically.
	// 以原子方式持久化完整课程元数据存储。
	if store.Items == nil {
		store.Items = map[string]learningCourseMetadataEntry{}
	}
	content, err := json.MarshalIndent(store, "", "  ")
	if err != nil {
		return err
	}
	path := learningCourseMetadataFilePath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	tempPath := path + ".tmp"
	if err := os.WriteFile(tempPath, content, 0o644); err != nil {
		return err
	}
	return os.Rename(tempPath, path)
}

func normalizeLearningCourseStatus(status string) (string, error) {
	// Normalize one lesson status value into the supported storage vocabulary.
	// 将课程状态值规范化为受支持的存储词汇。
	switch strings.ToLower(strings.TrimSpace(status)) {
	case LearningCourseStatusDraft:
		return LearningCourseStatusDraft, nil
	case LearningCourseStatusPublished:
		return LearningCourseStatusPublished, nil
	case LearningCourseStatusArchived:
		return LearningCourseStatusArchived, nil
	default:
		return "", ErrInvalidLearningCourseStatus
	}
}

func learningCourseStatusForPath(store learningCourseMetadataStore, path string) string {
	// Resolve the effective lesson status, defaulting seeded or legacy files to published visibility.
	// 解析生效课程状态，并将种子或历史文件默认视为已发布可见。
	entry, ok := store.Items[path]
	if !ok {
		if _, lessonFile := parseLearningCourseDescriptor(path); lessonFile {
			return LearningCourseStatusPublished
		}
		return ""
	}
	status, err := normalizeLearningCourseStatus(entry.Status)
	if err != nil {
		return LearningCourseStatusPublished
	}
	return status
}

func canAccessLearningMarkdownPath(path string, status string) bool {
	// Allow regular learners to access only published lesson files while keeping non-course markdown visible.
	// 普通学习用户仅可访问已发布课程文件，同时保留非课程 Markdown 的可见性。
	if _, lessonFile := parseLearningCourseDescriptor(path); !lessonFile {
		return true
	}
	return status == LearningCourseStatusPublished
}

type learningCourseDescriptor struct {
	// CourseID is the logical lesson identifier shared across locales.
	// CourseID 是跨语言共享的逻辑课程标识。
	CourseID string
	// Locale is the locale suffix derived from the markdown file name.
	// Locale 是从 Markdown 文件名推导出的语言版本后缀。
	Locale string
}

func parseLearningCourseDescriptor(relativePath string) (learningCourseDescriptor, bool) {
	// Parse one lesson file path following `courses/{courseId}.{locale}.md`.
	// 解析遵循 `courses/{courseId}.{locale}.md` 规则的课程文件路径。
	normalized := strings.TrimSpace(relativePath)
	if !strings.HasPrefix(normalized, "courses/") || !strings.HasSuffix(normalized, ".md") {
		return learningCourseDescriptor{}, false
	}
	fileName := strings.TrimPrefix(normalized, "courses/")
	lastDot := strings.LastIndex(fileName, ".")
	if lastDot <= 0 {
		return learningCourseDescriptor{}, false
	}
	localeDot := strings.LastIndex(fileName[:lastDot], ".")
	if localeDot <= 0 {
		return learningCourseDescriptor{}, false
	}
	courseID := fileName[:localeDot]
	locale := fileName[localeDot+1 : lastDot]
	if strings.TrimSpace(courseID) == "" || strings.TrimSpace(locale) == "" {
		return learningCourseDescriptor{}, false
	}
	return learningCourseDescriptor{
		CourseID: courseID,
		Locale:   locale,
	}, true
}
