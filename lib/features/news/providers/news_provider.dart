import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../models/news_category.dart';
import '../models/news_comment.dart';
import '../repositories/news_repository.dart';

enum NewsStatus { initial, loading, loaded, error }

class NewsProvider extends ChangeNotifier {
  final NewsRepository _repository;

  NewsStatus _status = NewsStatus.initial;
  List<NewsArticle> _articles = [];
  List<NewsArticle> _bookmarkedArticles = [];
  List<NewsCategory> _categories = [];
  Map<int, List<NewsComment>> _commentsMap = {};
  String? _errorMessage;

  NewsStatus get status => _status;
  List<NewsArticle> get articles => _articles;
  List<NewsArticle> get bookmarkedArticles => _bookmarkedArticles;
  List<NewsArticle> get featuredArticles =>
      _articles.where((a) => a.isFeatured == true).toList();
  List<NewsCategory> get categories => _categories;
  String? get errorMessage => _errorMessage;

  NewsProvider({NewsRepository? repository})
      : _repository = repository ?? NewsRepository();

  Future<void> loadNews({
    String? category,
    String? search,
    bool? featured,
    bool forceRefresh = false,
  }) async {
    _status = NewsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _articles = await _repository.getNews(
        category: category,
        search: search,
        featured: featured,
        forceRefresh: forceRefresh,
      );
      _status = NewsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = NewsStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshNews() async {
    await loadNews(forceRefresh: true);
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    try {
      _categories = await _repository.getCategories(forceRefresh: forceRefresh);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<NewsArticle> loadArticle(int id) async {
    try {
      final article = await _repository.getArticle(id);
      notifyListeners();
      return article;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  Future<void> toggleLike(int articleId) async {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final curr = _articles[index];
      final newIsLiked = !(curr.isLiked ?? false);
      final newLikeCount = (curr.likeCount ?? 0) + (newIsLiked ? 1 : -1);
      _articles[index] = curr.copyWith(isLiked: newIsLiked, likeCount: newLikeCount < 0 ? 0 : newLikeCount);
      notifyListeners();
    }

    try {
      final res = await _repository.toggleLike(articleId);
      if (res.isNotEmpty && index != -1) {
        final serverLiked = res['is_liked'] == true;
        final serverCount = res['like_count'] as int?;
        _articles[index] = _articles[index].copyWith(
          isLiked: serverLiked,
          likeCount: serverCount ?? _articles[index].likeCount,
        );
        notifyListeners();
      }
    } catch (e) {
      // Keep optimistic update or revert if error
    }
  }

  Future<void> toggleBookmark(int articleId) async {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final curr = _articles[index];
      final newIsBookmarked = !(curr.isBookmarked ?? false);
      _articles[index] = curr.copyWith(isBookmarked: newIsBookmarked);
      notifyListeners();
    }

    try {
      await _repository.toggleBookmark(articleId);
      await loadBookmarkedArticles();
    } catch (e) {
      // Revert if error
    }
  }

  Future<void> loadBookmarkedArticles() async {
    try {
      _bookmarkedArticles = await _repository.getBookmarks();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
  }

  List<NewsComment> getCommentsForNews(int newsId) {
    return _commentsMap[newsId] ?? [];
  }

  Future<void> loadComments(int newsId) async {
    try {
      final comments = await _repository.getComments(newsId);
      _commentsMap[newsId] = comments;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<NewsComment?> addComment(int newsId, String content, {int? parentId}) async {
    try {
      final newComment = await _repository.addComment(newsId, content, parentId: parentId);
      final currentList = _commentsMap[newsId] ?? [];
      _commentsMap[newsId] = [newComment, ...currentList];

      final index = _articles.indexWhere((a) => a.id == newsId);
      if (index != -1) {
        final curr = _articles[index];
        _articles[index] = curr.copyWith(commentCount: (curr.commentCount ?? 0) + 1);
      }
      notifyListeners();
      return newComment;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    }
  }

  Future<void> shareArticle(int newsId, {String? platform}) async {
    final index = _articles.indexWhere((a) => a.id == newsId);
    if (index != -1) {
      final curr = _articles[index];
      _articles[index] = curr.copyWith(shareCount: (curr.shareCount ?? 0) + 1);
      notifyListeners();
    }
    try {
      await _repository.share(newsId, platform: platform);
    } catch (e) {
      // ignore
    }
  }
}
