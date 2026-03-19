package service

import (
	"errors"
	"strings"
	"time"

	"gorm.io/gorm"

	"account-service/internal/models"
)

type PostView struct {
	// Post payload returned to clients.
	// 返回给客户端的文章视图。
	ID              string        `json:"id"`
	UserID          string        `json:"user_id"`
	SpaceID         string        `json:"space_id,omitempty"`
	SpaceName       string        `json:"space_name,omitempty"`
	SpaceSubdomain  string        `json:"space_subdomain,omitempty"`
	SpaceType       string        `json:"space_type,omitempty"`
	SpaceVisibility string        `json:"space_visibility,omitempty"`
	AuthorName      string        `json:"author_name"`
	Title           string        `json:"title"`
	Content         string        `json:"content"`
	Status          string        `json:"status"`
	Visibility      string        `json:"visibility"`
	LikesCount      int64         `json:"likes_count"`
	CommentsCount   int64         `json:"comments_count"`
	SharesCount     int64         `json:"shares_count"`
	LikedByMe       bool          `json:"liked_by_me"`
	CreatedAt       time.Time     `json:"created_at"`
	Comments        []CommentView `json:"comments,omitempty"`
}

type CommentView struct {
	// Comment payload returned to clients.
	// 返回给客户端的评论视图。
	ID         string    `json:"id"`
	PostID     string    `json:"post_id"`
	UserID     string    `json:"user_id"`
	AuthorName string    `json:"author_name"`
	Content    string    `json:"content"`
	CreatedAt  time.Time `json:"created_at"`
}

func CreatePost(db *gorm.DB, userID string, title string, content string, visibility string, spaceID string) (PostView, error) {
	// Create a post for the current user.
	// 为当前用户创建文章。
	return CreatePostWithStatus(db, userID, title, content, visibility, "published", spaceID)
}

func CreatePostWithStatus(db *gorm.DB, userID string, title string, content string, visibility string, status string, spaceID string) (PostView, error) {
	// Create a post for the current user with an explicit status.
	// 为当前用户创建带状态的文章。
	title = strings.TrimSpace(title)
	content = strings.TrimSpace(content)
	visibility = strings.ToLower(strings.TrimSpace(visibility))
	status = normalizePostStatus(status)
	spaceID = strings.TrimSpace(spaceID)
	if title == "" {
		return PostView{}, errors.New("title required")
	}
	if content == "" {
		return PostView{}, errors.New("content required")
	}
	if visibility == "" {
		visibility = "public"
	}
	if visibility != "public" && visibility != "private" {
		return PostView{}, errors.New("visibility must be public or private")
	}

	space, err := resolveSpaceForPost(db, userID, visibility, spaceID)
	if err != nil {
		return PostView{}, err
	}

	post := models.Post{
		UserID:     userID,
		SpaceID:    space.ID,
		Title:      title,
		Content:    content,
		Status:     status,
		Visibility: visibility,
	}
	if err := db.Create(&post).Error; err != nil {
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

func GetPost(db *gorm.DB, viewerID string, postID string) (PostView, error) {
	// Get one post with aggregate counters and comments.
	// 获取单篇文章及聚合计数和评论。
	var post models.Post
	if err := db.First(&post, "id = ?", postID).Error; err != nil {
		return PostView{}, err
	}
	if post.Status == "hidden" && post.UserID != viewerID {
		return PostView{}, gorm.ErrRecordNotFound
	}
	if post.Status == "draft" && post.UserID != viewerID {
		return PostView{}, gorm.ErrRecordNotFound
	}
	if post.Visibility == "private" && post.UserID != viewerID {
		return PostView{}, gorm.ErrRecordNotFound
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

func UpdatePost(db *gorm.DB, userID string, postID string, title string, content string, visibility string, status string, spaceID string) (PostView, error) {
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
	if content == "" {
		return PostView{}, errors.New("content required")
	}
	if visibility != "public" && visibility != "private" {
		return PostView{}, errors.New("visibility must be public or private")
	}

	var post models.Post
	if err := db.First(&post, "id = ?", postID).Error; err != nil {
		return PostView{}, err
	}
	if post.UserID != userID {
		return PostView{}, errors.New("cannot edit another user's post")
	}

	resolvedSpaceID := spaceID
	if resolvedSpaceID == "" {
		resolvedSpaceID = post.SpaceID
	}
	space, err := resolveSpaceForPost(db, userID, visibility, resolvedSpaceID)
	if err != nil {
		return PostView{}, err
	}

	updates := map[string]any{
		"title":      title,
		"content":    content,
		"space_id":   space.ID,
		"visibility": visibility,
		"status":     status,
		"updated_at": time.Now(),
	}
	if err := db.Model(&post).Updates(updates).Error; err != nil {
		return PostView{}, err
	}
	return GetPost(db, userID, postID)
}

func DeletePost(db *gorm.DB, userID string, postID string) error {
	// Delete an existing post owned by the current user.
	// 删除当前用户拥有的文章。
	return db.Transaction(func(tx *gorm.DB) error {
		var post models.Post
		if err := tx.First(&post, "id = ? AND user_id = ?", postID, userID).Error; err != nil {
			return err
		}
		return deletePostCascade(tx, []string{post.ID})
	})
}

func AddComment(db *gorm.DB, userID string, postID string, content string) (PostView, error) {
	// Add a comment to a post.
	// 为文章新增评论。
	content = strings.TrimSpace(content)
	if content == "" {
		return PostView{}, errors.New("content required")
	}
	post, err := GetPost(db, userID, postID)
	if err != nil {
		return PostView{}, err
	}
	comment := models.Comment{
		PostID:    post.ID,
		UserID:    userID,
		Content:   content,
		Status:    "published",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
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
		SpaceName:       space.Name,
		SpaceSubdomain:  space.Subdomain,
		SpaceType:       space.Type,
		SpaceVisibility: spaceVisibilityValue(space),
		AuthorName:      fallbackDisplayName(user),
		Title:           post.Title,
		Content:         post.Content,
		Status:          post.Status,
		Visibility:      post.Visibility,
		CreatedAt:       post.CreatedAt,
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
			ID:         comment.ID,
			PostID:     comment.PostID,
			UserID:     comment.UserID,
			AuthorName: fallbackDisplayName(author),
			Content:    comment.Content,
			CreatedAt:  comment.CreatedAt,
		})
	}
	return view, nil
}

func resolveSpaceForPost(db *gorm.DB, userID string, visibility string, spaceID string) (models.Space, error) {
	// Resolve the target space for a post write operation.
	// 为文章写入操作解析目标空间。
	visibility = strings.ToLower(strings.TrimSpace(visibility))
	spaceID = strings.TrimSpace(spaceID)

	if spaceID != "" {
		space, err := loadOwnedSpaceByID(db, userID, spaceID)
		if err != nil {
			return models.Space{}, err
		}
		if space.Type != visibility {
			return models.Space{}, errors.New("space type does not match visibility")
		}
		return space, nil
	}

	space, err := firstSpaceByType(db, userID, visibility)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return models.Space{}, errors.New("space required for this visibility")
		}
		return models.Space{}, err
	}
	return space, nil
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
	if user.Email != nil && strings.TrimSpace(*user.Email) != "" {
		return *user.Email
	}
	if user.Phone != nil && strings.TrimSpace(*user.Phone) != "" {
		return *user.Phone
	}
	return user.ID
}

func deletePostCascade(tx *gorm.DB, postIDs []string) error {
	// Delete a post and all of its dependent interactions.
	// 删除文章及其所有关联互动数据。
	if len(postIDs) == 0 {
		return nil
	}
	if err := tx.Where("post_id IN ?", postIDs).Delete(&models.Comment{}).Error; err != nil {
		return err
	}
	if err := tx.Where("post_id IN ?", postIDs).Delete(&models.PostLike{}).Error; err != nil {
		return err
	}
	if err := tx.Where("post_id IN ?", postIDs).Delete(&models.PostShare{}).Error; err != nil {
		return err
	}
	if err := tx.Where("id IN ?", postIDs).Delete(&models.Post{}).Error; err != nil {
		return err
	}
	return nil
}
