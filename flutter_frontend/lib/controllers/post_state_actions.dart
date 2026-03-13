import '../models/app_models.dart';

class PostStateSnapshot {
  const PostStateSnapshot({
    required this.publicPosts,
    required this.privatePosts,
    required this.profilePosts,
    required this.currentPost,
  });

  final List<PostItem> publicPosts;
  final List<PostItem> privatePosts;
  final List<PostItem> profilePosts;
  final PostItem? currentPost;
}

class PostStateActions {
  const PostStateActions._();

  static List<PostItem> syncVisibility(
    List<PostItem> items,
    PostItem updated,
    String visibility,
  ) {
    final next = [...items];
    final index = next.indexWhere((post) => post.id == updated.id);
    final shouldExist = updated.visibility == visibility;
    if (index >= 0 && !shouldExist) {
      next.removeAt(index);
    } else if (index >= 0) {
      next[index] = updated;
    } else if (shouldExist) {
      next.insert(0, updated);
    }
    return next;
  }

  static PostStateSnapshot applyPostUpdate({
    required PostItem updated,
    required List<PostItem> publicPosts,
    required List<PostItem> privatePosts,
    required List<PostItem> profilePosts,
    required PostItem? currentPost,
  }) {
    final nextProfilePosts = [...profilePosts];
    final profileIndex = nextProfilePosts.indexWhere(
      (post) => post.id == updated.id,
    );
    if (profileIndex >= 0) {
      nextProfilePosts[profileIndex] = updated;
    }

    return PostStateSnapshot(
      publicPosts: syncVisibility(publicPosts, updated, 'public'),
      privatePosts: syncVisibility(privatePosts, updated, 'private'),
      profilePosts: nextProfilePosts,
      currentPost: currentPost?.id == updated.id ? updated : currentPost,
    );
  }
}
