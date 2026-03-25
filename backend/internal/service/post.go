package service

import (
	"encoding/json"
	"errors"
	"strings"
	"time"

	"gorm.io/gorm"

	"account-service/internal/models"
)

type PostView struct {
	// Post payload returned to clients.
	// 返回给客户端的文章视图。
	ID              string          `json:"id"`
	UserID          string          `json:"user_id"`
	SpaceID         string          `json:"space_id,omitempty"`
	SpaceUserID     string          `json:"space_user_id,omitempty"`
	SpaceName       string          `json:"space_name,omitempty"`
	SpaceSubdomain  string          `json:"space_subdomain,omitempty"`
	SpaceType       string          `json:"space_type,omitempty"`
	SpaceVisibility string          `json:"space_visibility,omitempty"`
	AuthorName      string          `json:"author_name"`
	Title           string          `json:"title"`
	Content         string          `json:"content"`
	MediaType       string          `json:"media_type,omitempty"`
	MediaName       string          `json:"media_name,omitempty"`
	MediaMime       string          `json:"media_mime,omitempty"`
	MediaData       string          `json:"media_data,omitempty"`
	MediaItems      []PostMediaItem `json:"media_items,omitempty"`
	Status          string          `json:"status"`
	Visibility      string          `json:"visibility"`
	LikesCount      int64           `json:"likes_count"`
	CommentsCount   int64           `json:"comments_count"`
	SharesCount     int64           `json:"shares_count"`
	LikedByMe       bool            `json:"liked_by_me"`
	CreatedAt       time.Time       `json:"created_at"`
	Comments        []CommentView   `json:"comments,omitempty"`
}

type PostMediaItem struct {
	// Post media payload for a single image or video item.
	// 单个图片或视频媒体载荷。
	MediaType string `json:"media_type,omitempty"`
	MediaName string `json:"media_name,omitempty"`
	MediaMime string `json:"media_mime,omitempty"`
	MediaData string `json:"media_data,omitempty"`
}

type CommentView struct {
	// Comment payload returned to clients.
	// 返回给客户端的评论视图。
	ID              string    `json:"id"`
	PostID          string    `json:"post_id"`
	UserID          string    `json:"user_id"`
	ParentCommentID *string   `json:"parent_comment_id,omitempty"`
	AuthorName      string    `json:"author_name"`
	Content         string    `json:"content"`
	CreatedAt       time.Time `json:"created_at"`
}

func CreatePost(db *gorm.DB, userID string, title string, content string, visibility string, spaceID string) (PostView, error) {
	// Create a post for the current user.
	// 为当前用户创建文章。
	return CreatePostWithStatus(db, userID, title, content, visibility, "published", spaceID, "", "", "", "", nil)
}

func CreatePostWithStatus(db *gorm.DB, userID string, title string, content string, visibility string, status string, spaceID string, mediaType string, mediaName string, mediaMime string, mediaData string, mediaItems []PostMediaItem) (PostView, error) {
	// Create a post for the current user with an explicit status.
	// 为当前用户创建带状态的文章。
	title = strings.TrimSpace(title)
	content = strings.TrimSpace(content)
	visibility = strings.ToLower(strings.TrimSpace(visibility))
	status = normalizePostStatus(status)
	spaceID = strings.TrimSpace(spaceID)
	mediaType, mediaName, mediaMime, mediaData, normalizedMediaItems, err := normalizePostMediaPayload(mediaType, mediaName, mediaMime, mediaData, mediaItems)
	if err != nil {
		return PostView{}, err
	}
	if title == "" {
		return PostView{}, errors.New("title required")
	}
	if content == "" && mediaData == "" {
		return PostView{}, errors.New("content required")
	}
	if visibility == "" {
		visibility = "public"
	}
	if visibility != "public" && visibility != "private" {
		return PostView{}, errors.New("visibility must be public or private")
	}

	space, err := resolveOwnedSpaceForPost(db, userID, spaceID)
	if err != nil {
		return PostView{}, err
	}

	postID := newPostRecordID()
	persistedMediaItems, writtenMediaRefs, err := persistPostMediaItems(postID, normalizedMediaItems, nil)
	if err != nil {
		cleanupPostMediaFiles(writtenMediaRefs, true)
		return PostView{}, err
	}
	if len(persistedMediaItems) > 0 {
		primary := persistedMediaItems[0]
		mediaType = primary.MediaType
		mediaName = primary.MediaName
		mediaMime = primary.MediaMime
		mediaData = primary.MediaData
	}

	post := models.Post{
		ID:         postID,
		UserID:     userID,
		SpaceID:    space.ID,
		Title:      title,
		Content:    content,
		MediaType:  mediaType,
		MediaName:  mediaName,
		MediaMime:  mediaMime,
		MediaData:  mediaData,
		Status:     status,
		Visibility: visibility,
	}
	mediaItemsJSON, err := serializePostMediaItems(persistedMediaItems)
	if err != nil {
		cleanupPostMediaFiles(writtenMediaRefs, true)
		return PostView{}, err
	}
	post.MediaItems = mediaItemsJSON
	if err := db.Create(&post).Error; err != nil {
		cleanupPostMediaFiles(writtenMediaRefs, true)
		return PostView{}, err
	}
	return GetPost(db, userID, post.ID)
}

func ListPosts(db *gorm.DB, viewerID string, visibility string, limit int) ([]PostView, error) {
	// List posts visible to the current viewer.
	// 列出当前查看者可见的文章。
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	visibility = strings.ToLower(strings.TrimSpace(visibility))

	query := db.Model(&models.Post{}).Order("created_at desc").Limit(limit)
	query = query.Where("status = ?", "published")
	if visibility == "private" {
		query = query.Where("visibility = ? AND user_id = ?", "private", viewerID)
	} else {
		query = query.Where("visibility = ?", "public")
	}

	var posts []models.Post
	if err := query.Find(&posts).Error; err != nil {
		return nil, err
	}
	return buildPostViews(db, viewerID, posts)
}

func ListPostsByUser(db *gorm.DB, viewerID string, ownerID string, visibility string, limit int) ([]PostView, error) {
	// List posts for a specific user with visibility checks.
	// 按指定用户列出文章，并执行可见性校验。
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	visibility = strings.ToLower(strings.TrimSpace(visibility))

	query := db.Model(&models.Post{}).Where("user_id = ?", ownerID).Order("created_at desc").Limit(limit)
	if visibility == "private" {
		if viewerID != ownerID {
			return []PostView{}, nil
		}
		query = query.Where("visibility = ? AND status <> ?", "private", "hidden")
	} else if visibility == "all" && viewerID == ownerID {
		// Owners can see both public and private posts.
		// 作者本人可以同时看到公开和私密文章。
		query = query.Where("status <> ?", "hidden")
	} else {
		query = query.Where("visibility = ? AND status = ?", "public", "published")
	}

	var posts []models.Post
	if err := query.Find(&posts).Error; err != nil {
		return nil, err
	}
	return buildPostViews(db, viewerID, posts)
}

func ListSpacePosts(db *gorm.DB, viewerID string, spaceID string, visibility string, limit int) ([]PostView, error) {
	// List posts inside one space while honoring creator and viewer visibility.
	// 列出单个空间中的文章，并同时遵守创建者与查看者的可见性。
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	spaceID = strings.TrimSpace(spaceID)
	if spaceID == "" {
		return nil, errors.New("space required")
	}
	visibility = strings.ToLower(strings.TrimSpace(visibility))

	var space models.Space
	if err := db.First(&space, "id = ?", spaceID).Error; err != nil {
		return nil, err
	}

	friendIDs, err := loadAcceptedFriendIDs(db, viewerID)
	if err != nil {
		return nil, err
	}
	if !canViewSpace(viewerID, friendIDs, space) {
		return nil, gorm.ErrRecordNotFound
	}

	query := db.Model(&models.Post{}).
		Where("space_id = ?", space.ID).
		Order("created_at desc").
		Limit(limit)

	if viewerID == space.UserID {
		switch visibility {
		case "public", "private":
			query = query.Where("visibility = ?", visibility)
		case "", "all":
			// Keep all creator-owned posts, including drafts and hidden items.
			// 保留创建者可见的全部文章，包括草稿和隐藏内容。
		default:
			query = query.Where("visibility = ?", "public")
		}
	} else {
		if visibility == "private" {
			return []PostView{}, nil
		}
		query = query.Where("visibility = ? AND status = ?", "public", "published")
	}

	var posts []models.Post
	if err := query.Find(&posts).Error; err != nil {
		return nil, err
	}
	return buildPostViews(db, viewerID, posts)
}

func GetPost(db *gorm.DB, viewerID string, postID string) (PostView, error) {
	// Get one post with aggregate counters and comments.
	// 获取单篇文章及聚合计数和评论。
	var post models.Post
	if err := db.First(&post, "id = ?", postID).Error; err != nil {
		return PostView{}, err
	}
	views, err := buildPostViews(db, viewerID, []models.Post{post})
	if err != nil {
		return PostView{}, err
	}
	if len(views) == 0 {
		return PostView{}, gorm.ErrRecordNotFound
	}
	return views[0], nil
}

func ToggleLikePost(db *gorm.DB, userID string, postID string) (PostView, error) {
	// Toggle like on a post for the current user.
	// 为当前用户切换文章点赞状态。
	post, err := GetPost(db, userID, postID)
	if err != nil {
		return PostView{}, err
	}
	var like models.PostLike
	err = db.Where("post_id = ? AND user_id = ?", postID, userID).First(&like).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		if err := db.Create(&models.PostLike{PostID: postID, UserID: userID, Status: "active", CreatedAt: time.Now()}).Error; err != nil {
			return PostView{}, err
		}
	} else if err != nil {
		return PostView{}, err
	} else {
		if err := db.Delete(&like).Error; err != nil {
			return PostView{}, err
		}
	}
	return GetPost(db, userID, post.ID)
}

func UpdatePost(db *gorm.DB, userID string, postID string, title string, content string, visibility string, status string, spaceID string, mediaType string, mediaName string, mediaMime string, mediaData string, mediaItems []PostMediaItem, clearMedia bool) (PostView, error) {
	// Update an existing post owned by the current user.
	// 更新当前用户拥有的文章。
	title = strings.TrimSpace(title)
	content = strings.TrimSpace(content)
	visibility = strings.ToLower(strings.TrimSpace(visibility))
	status = normalizePostStatus(status)
	spaceID = strings.TrimSpace(spaceID)
	if title == "" {
		return PostView{}, errors.New("title required")
	}
	if visibility != "public" && visibility != "private" {
		return PostView{}, errors.New("visibility must be public or private")
	}

	var post models.Post
	if err := db.First(&post, "id = ?", postID).Error; err != nil {
		return PostView{}, err
	}
	managed, err := canManagePost(db, userID, post)
	if err != nil {
		return PostView{}, err
	}
	if !managed {
		return PostView{}, errors.New("cannot edit another user's post")
	}

	resolvedSpaceID := spaceID
	if resolvedSpaceID == "" {
		resolvedSpaceID = post.SpaceID
	}
	space, err := resolveOwnedSpaceForPost(db, userID, resolvedSpaceID)
	if err != nil {
		return PostView{}, err
	}

	existingMediaItems := loadPostMediaItems(post)
	finalMediaItems := existingMediaItems
	var writtenMediaRefs []postMediaFileRef

	if clearMedia {
		// Explicit clear requests must remove the current media instead of preserving it.
		// 显式清除媒体时必须移除当前媒体，不能继续沿用旧内容。
		mediaType = "text"
		mediaName = ""
		mediaMime = ""
		mediaData = ""
		finalMediaItems = nil
	} else {
		mediaType, mediaName, mediaMime, mediaData, mediaItems, err = normalizePostMediaPayload(
			mediaType,
			mediaName,
			mediaMime,
			mediaData,
			mediaItems,
		)
		if err != nil {
			return PostView{}, err
		}
		if mediaData == "" {
			mediaType = post.MediaType
			mediaName = post.MediaName
			mediaMime = post.MediaMime
			mediaData = post.MediaData
			finalMediaItems = existingMediaItems
		} else if samePostMediaItems(existingMediaItems, mediaItems) && postMediaFilesExist(post.ID, existingMediaItems) {
			finalMediaItems = existingMediaItems
		} else {
			finalMediaItems, writtenMediaRefs, err = persistPostMediaItems(post.ID, mediaItems, existingMediaItems)
			if err != nil {
				cleanupPostMediaFiles(writtenMediaRefs, false)
				return PostView{}, err
			}
		}
	}
	if len(finalMediaItems) > 0 {
		primary := finalMediaItems[0]
		mediaType = primary.MediaType
		mediaName = primary.MediaName
		mediaMime = primary.MediaMime
		mediaData = primary.MediaData
	} else {
		mediaType = "text"
		mediaName = ""
		mediaMime = ""
		mediaData = ""
	}
	if content == "" && mediaData == "" {
		return PostView{}, errors.New("content required")
	}

	updates := map[string]any{
		"title":      title,
		"content":    content,
		"space_id":   space.ID,
		"media_type": mediaType,
		"media_name": mediaName,
		"media_mime": mediaMime,
		"media_data": mediaData,
		"visibility": visibility,
		"status":     status,
		"updated_at": time.Now(),
	}
	mediaItemsJSON, err := serializePostMediaItems(finalMediaItems)
	if err != nil {
		cleanupPostMediaFiles(writtenMediaRefs, false)
		return PostView{}, err
	}
	updates["media_items"] = mediaItemsJSON
	if err := db.Model(&post).Updates(updates).Error; err != nil {
		cleanupPostMediaFiles(writtenMediaRefs, false)
		return PostView{}, err
	}
	cleanupPostMediaFiles(diffRemovedPostMediaRefs(post.ID, existingMediaItems, finalMediaItems), false)
	return GetPost(db, userID, postID)
}

func DeletePost(db *gorm.DB, userID string, postID string) error {
	// Delete an existing post owned by the current user.
	// 删除当前用户拥有的文章。
	var mediaRefs []postMediaFileRef
	err := db.Transaction(func(tx *gorm.DB) error {
		var post models.Post
		if err := tx.First(&post, "id = ?", postID).Error; err != nil {
			return err
		}
		managed, err := canManagePost(tx, userID, post)
		if err != nil {
			return err
		}
		if !managed {
			return errors.New("cannot delete another user's post")
		}
		refs, err := deletePostCascade(tx, []string{post.ID})
		if err != nil {
			return err
		}
		mediaRefs = refs
		return nil
	})
	if err != nil {
		return err
	}
	cleanupPostMediaFiles(mediaRefs, true)
	return nil
}

func AddComment(db *gorm.DB, userID string, postID string, content string, parentCommentID string) (PostView, error) {
	// Add a comment to a post.
	// 为文章新增评论。
	content = strings.TrimSpace(content)
	parentCommentID = strings.TrimSpace(parentCommentID)
	if content == "" {
		return PostView{}, errors.New("content required")
	}
	post, err := GetPost(db, userID, postID)
	if err != nil {
		return PostView{}, err
	}
	var resolvedParentCommentID *string
	if parentCommentID != "" {
		var parentComment models.Comment
		if err := db.First(&parentComment, "id = ? AND post_id = ?", parentCommentID, post.ID).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return PostView{}, errors.New("parent comment not found")
			}
			return PostView{}, err
		}
		parentID := parentComment.ID
		resolvedParentCommentID = &parentID
	}
	comment := models.Comment{
		PostID:          post.ID,
		UserID:          userID,
		ParentCommentID: resolvedParentCommentID,
		Content:         content,
		Status:          "published",
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}
	if err := db.Create(&comment).Error; err != nil {
		return PostView{}, err
	}
	return GetPost(db, userID, post.ID)
}

func SharePost(db *gorm.DB, userID string, postID string) (PostView, error) {
	// Record a repost/share action.
	// 记录一次转发动作。
	post, err := GetPost(db, userID, postID)
	if err != nil {
		return PostView{}, err
	}
	share := models.PostShare{
		PostID:    post.ID,
		UserID:    userID,
		ShareType: "repost",
		Status:    "active",
		CreatedAt: time.Now(),
	}
	if err := db.Create(&share).Error; err != nil {
		return PostView{}, err
	}
	return GetPost(db, userID, post.ID)
}

func buildPostViews(db *gorm.DB, viewerID string, posts []models.Post) ([]PostView, error) {
	// Expand posts with author names, counts, and comments.
	// 为文章补充作者名、计数和评论。
	friendIDs, err := loadAcceptedFriendIDs(db, viewerID)
	if err != nil {
		return nil, err
	}
	items := make([]PostView, 0, len(posts))
	for _, post := range posts {
		if !canViewPost(viewerID, friendIDs, post) {
			continue
		}
		view, err := hydratePostView(db, viewerID, friendIDs, post)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				continue
			}
			return nil, err
		}
		items = append(items, view)
	}
	return items, nil
}

func hydratePostView(db *gorm.DB, viewerID string, friendIDs map[string]struct{}, post models.Post) (PostView, error) {
	var user models.User
	if err := db.Select("id", "display_name", "email", "phone").First(&user, "id = ?", post.UserID).Error; err != nil {
		return PostView{}, err
	}

	space, err := resolvePostSpaceForView(db, post)
	if err != nil {
		return PostView{}, err
	}
	if !canViewSpace(viewerID, friendIDs, space) {
		return PostView{}, gorm.ErrRecordNotFound
	}

	view := PostView{
		ID:              post.ID,
		UserID:          post.UserID,
		SpaceID:         space.ID,
		SpaceUserID:     space.UserID,
		SpaceName:       space.Name,
		SpaceSubdomain:  space.Subdomain,
		SpaceType:       space.Type,
		SpaceVisibility: spaceVisibilityValue(space),
		AuthorName:      fallbackDisplayName(user),
		Title:           post.Title,
		Content:         post.Content,
		MediaType:       strings.TrimSpace(post.MediaType),
		MediaName:       strings.TrimSpace(post.MediaName),
		MediaMime:       strings.TrimSpace(post.MediaMime),
		MediaData:       strings.TrimSpace(post.MediaData),
		Status:          post.Status,
		Visibility:      post.Visibility,
		CreatedAt:       post.CreatedAt,
	}
	view.MediaItems = loadPostMediaItems(post)
	if len(view.MediaItems) > 0 {
		primary := view.MediaItems[0]
		view.MediaType = primary.MediaType
		view.MediaName = primary.MediaName
		view.MediaMime = primary.MediaMime
		view.MediaData = primary.MediaData
	} else {
		view.MediaType = normalizePostMediaType(post.MediaType, post.MediaMime, post.MediaName, post.MediaData)
	}

	_ = db.Model(&models.PostLike{}).Where("post_id = ?", post.ID).Count(&view.LikesCount).Error
	_ = db.Model(&models.Comment{}).Where("post_id = ?", post.ID).Count(&view.CommentsCount).Error
	_ = db.Model(&models.PostShare{}).Where("post_id = ?", post.ID).Count(&view.SharesCount).Error

	var like models.PostLike
	if err := db.Where("post_id = ? AND user_id = ?", post.ID, viewerID).First(&like).Error; err == nil {
		view.LikedByMe = true
	}

	var comments []models.Comment
	if err := db.Where("post_id = ?", post.ID).Order("created_at asc").Find(&comments).Error; err != nil {
		return PostView{}, err
	}
	view.Comments = make([]CommentView, 0, len(comments))
	for _, comment := range comments {
		var author models.User
		if err := db.Select("id", "display_name", "email", "phone").First(&author, "id = ?", comment.UserID).Error; err != nil {
			return PostView{}, err
		}
		view.Comments = append(view.Comments, CommentView{
			ID:              comment.ID,
			PostID:          comment.PostID,
			UserID:          comment.UserID,
			ParentCommentID: comment.ParentCommentID,
			AuthorName:      fallbackDisplayName(author),
			Content:         comment.Content,
			CreatedAt:       comment.CreatedAt,
		})
	}
	return view, nil
}

func canViewPost(viewerID string, friendIDs map[string]struct{}, post models.Post) bool {
	// Decide whether the current viewer can see a post.
	// 判断当前查看者是否可以看到某篇文章。
	if strings.TrimSpace(post.UserID) == strings.TrimSpace(viewerID) {
		return true
	}
	switch strings.ToLower(strings.TrimSpace(post.Status)) {
	case "draft", "hidden":
		return false
	}
	switch strings.ToLower(strings.TrimSpace(post.Visibility)) {
	case "public":
		return true
	case "friends":
		_, ok := friendIDs[post.UserID]
		return ok
	default:
		return false
	}
}

func canManagePost(db *gorm.DB, userID string, post models.Post) (bool, error) {
	// Decide whether the current user can manage a post.
	// 判断当前用户是否可以管理某篇文章。
	if strings.TrimSpace(post.UserID) == strings.TrimSpace(userID) {
		return true, nil
	}
	space, err := resolvePostSpaceForView(db, post)
	if err != nil {
		return false, err
	}
	return strings.TrimSpace(space.UserID) == strings.TrimSpace(userID), nil
}

func resolveOwnedSpaceForPost(db *gorm.DB, userID string, spaceID string) (models.Space, error) {
	// Resolve the owned space selected for a post write operation.
	// 为文章写入操作解析当前用户选择的空间。
	spaceID = strings.TrimSpace(spaceID)
	if spaceID == "" {
		return models.Space{}, errors.New("space required")
	}
	return loadOwnedSpaceByID(db, userID, spaceID)
}

func resolvePostSpaceForView(db *gorm.DB, post models.Post) (models.Space, error) {
	// Resolve the space metadata for a post response.
	// 为文章响应解析空间元数据。
	if strings.TrimSpace(post.SpaceID) != "" {
		var space models.Space
		err := db.First(&space, "id = ?", post.SpaceID).Error
		if err == nil {
			return space, nil
		} else if !errors.Is(err, gorm.ErrRecordNotFound) {
			return models.Space{}, err
		}
	}

	space, err := firstSpaceByType(db, post.UserID, post.Visibility)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return models.Space{}, nil
		}
		return models.Space{}, err
	}
	return space, nil
}

func loadPostMediaItems(post models.Post) []PostMediaItem {
	// Load the stored media gallery or fall back to the legacy single-media payload.
	// 读取已存储的媒体集合，或回退到旧版单媒体载荷。
	if mediaItemsJSON := strings.TrimSpace(post.MediaItems); mediaItemsJSON != "" {
		var items []PostMediaItem
		if err := json.Unmarshal([]byte(mediaItemsJSON), &items); err == nil {
			if normalized := normalizePostMediaItems(items); len(normalized) > 0 {
				return normalized
			}
		}
	}
	legacy := normalizePostMediaItem(post.MediaType, post.MediaName, post.MediaMime, post.MediaData)
	if legacy.MediaData != "" {
		return []PostMediaItem{legacy}
	}
	return nil
}

func normalizePostMediaItems(mediaItems []PostMediaItem) []PostMediaItem {
	// Normalize a media list and keep image galleries compact.
	// 规范化媒体列表，并让图片集合保持紧凑。
	if len(mediaItems) == 0 {
		return nil
	}
	normalized := make([]PostMediaItem, 0, len(mediaItems))
	for _, item := range mediaItems {
		normalizedItem := normalizePostMediaItem(item.MediaType, item.MediaName, item.MediaMime, item.MediaData)
		if normalizedItem.MediaData == "" {
			continue
		}
		normalized = append(normalized, normalizedItem)
	}
	if len(normalized) <= 1 {
		return normalized
	}
	imageItems := make([]PostMediaItem, 0, len(normalized))
	for _, item := range normalized {
		if item.MediaType == "image" {
			imageItems = append(imageItems, item)
		}
	}
	if len(imageItems) > 0 {
		return imageItems
	}
	return normalized[:1]
}

func normalizePostMediaItem(mediaType string, mediaName string, mediaMime string, mediaData string) PostMediaItem {
	// Normalize one media item before persisting it.
	// 在保存前规范化单个媒体项。
	mediaName = strings.TrimSpace(mediaName)
	mediaMime = strings.TrimSpace(mediaMime)
	mediaData = strings.TrimSpace(mediaData)
	mediaType = normalizePostMediaType(mediaType, mediaMime, mediaName, mediaData)
	if mediaType == "text" || mediaData == "" {
		return PostMediaItem{}
	}
	if mediaType != "image" && mediaType != "video" {
		return PostMediaItem{}
	}
	return PostMediaItem{
		MediaType: mediaType,
		MediaName: mediaName,
		MediaMime: mediaMime,
		MediaData: mediaData,
	}
}

func normalizePostMediaPayload(mediaType string, mediaName string, mediaMime string, mediaData string, mediaItems []PostMediaItem) (string, string, string, string, []PostMediaItem, error) {
	// Normalize the primary media fields and the optional media gallery together.
	// 一并规范化主媒体字段与可选媒体集合。
	normalizedItems := normalizePostMediaItems(mediaItems)
	if len(normalizedItems) == 0 {
		legacyItem := normalizePostMediaItem(mediaType, mediaName, mediaMime, mediaData)
		if legacyItem.MediaData != "" {
			normalizedItems = []PostMediaItem{legacyItem}
		}
	}
	if len(normalizedItems) == 0 {
		return "", "", "", "", nil, nil
	}
	primary := normalizedItems[0]
	return primary.MediaType, primary.MediaName, primary.MediaMime, primary.MediaData, normalizedItems, nil
}

func serializePostMediaItems(mediaItems []PostMediaItem) (string, error) {
	// Serialize the media gallery into a stable JSON payload for storage.
	// 将媒体集合序列化为稳定的 JSON 载荷以便存储。
	if len(mediaItems) == 0 {
		return "", nil
	}
	payload, err := json.Marshal(mediaItems)
	if err != nil {
		return "", err
	}
	return string(payload), nil
}

func normalizePostMediaType(mediaType string, mediaMime string, mediaName string, mediaData string) string {
	// Normalize post media type and infer from MIME or file name when needed.
	// 规范化文章媒体类型，并在必要时从 MIME 或文件名推断。
	value := strings.ToLower(strings.TrimSpace(mediaType))
	switch value {
	case "text":
		return "text"
	case "image", "video":
		return value
	}
	if strings.TrimSpace(mediaData) == "" && strings.TrimSpace(mediaName) == "" && strings.TrimSpace(mediaMime) == "" {
		return "text"
	}
	mime := strings.ToLower(strings.TrimSpace(mediaMime))
	switch {
	case strings.HasPrefix(mime, "image/"):
		return "image"
	case strings.HasPrefix(mime, "video/"):
		return "video"
	}
	name := strings.ToLower(strings.TrimSpace(mediaName))
	switch {
	case strings.HasSuffix(name, ".png"),
		strings.HasSuffix(name, ".jpg"),
		strings.HasSuffix(name, ".jpeg"),
		strings.HasSuffix(name, ".gif"),
		strings.HasSuffix(name, ".webp"):
		return "image"
	case strings.HasSuffix(name, ".mp4"),
		strings.HasSuffix(name, ".mov"),
		strings.HasSuffix(name, ".webm"),
		strings.HasSuffix(name, ".mkv"):
		return "video"
	}
	return "text"
}

func normalizePostStatus(status string) string {
	// Normalize and validate post status values.
	// 规范化并校验文章状态值。
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "draft":
		return "draft"
	case "hidden":
		return "hidden"
	default:
		return "published"
	}
}

func fallbackDisplayName(user models.User) string {
	// Pick the best available display label for a user.
	// 为用户选择最佳展示名称。
	if strings.TrimSpace(user.DisplayName) != "" {
		return user.DisplayName
	}
	// Public author surfaces must not fall back to private contact data.
	// 公开作者展示位不能回退到私密联系方式。
	if username := strings.TrimSpace(stringValue(user.Username)); username != "" {
		return username
	}
	if domain := strings.TrimSpace(stringValue(user.Domain)); domain != "" {
		return domain
	}
	return user.ID
}

func deletePostCascade(tx *gorm.DB, postIDs []string) ([]postMediaFileRef, error) {
	// Delete a post and all of its dependent interactions.
	// 删除文章及其所有关联互动数据。
	if len(postIDs) == 0 {
		return nil, nil
	}
	var posts []models.Post
	if err := tx.Where("id IN ?", postIDs).Find(&posts).Error; err != nil {
		return nil, err
	}
	if err := tx.Where("post_id IN ?", postIDs).Delete(&models.Comment{}).Error; err != nil {
		return nil, err
	}
	if err := tx.Where("post_id IN ?", postIDs).Delete(&models.PostLike{}).Error; err != nil {
		return nil, err
	}
	if err := tx.Where("post_id IN ?", postIDs).Delete(&models.PostShare{}).Error; err != nil {
		return nil, err
	}
	if err := tx.Where("id IN ?", postIDs).Delete(&models.Post{}).Error; err != nil {
		return nil, err
	}
	refs := make([]postMediaFileRef, 0)
	for _, post := range posts {
		refs = append(refs, collectPostMediaRefs(post.ID, loadPostMediaItems(post))...)
	}
	return refs, nil
}
