import 'package:hive_flutter/hive_flutter.dart';
import '../services/news_api_service.dart';
import '../models/news_article.dart';
import '../models/news_category.dart';
import '../models/news_comment.dart';

class NewsRepository {
  final NewsApiService _apiService;
  final Box<NewsArticle>? _articlesBox;
  final Box<NewsCategory>? _categoriesBox;

  NewsRepository({
    NewsApiService? apiService,
    Box<NewsArticle>? articlesBox,
    Box<NewsCategory>? categoriesBox,
  })  : _apiService = apiService ?? NewsApiService(),
        _articlesBox = articlesBox,
        _categoriesBox = categoriesBox;

  Future<List<NewsArticle>> getNews({
    String? category,
    String? search,
    bool? featured,
    int? page,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _articlesBox != null &&
        _articlesBox!.isNotEmpty &&
        category == null &&
        search == null &&
        featured == null) {
      return _articlesBox!.values.toList();
    }

    try {
      final response = await _apiService.getNews(
        category: category,
        search: search,
        featured: featured,
        page: page,
      );
      final articles = response.data ?? [];
      if (_articlesBox != null && category == null && search == null && featured == null) {
        await _articlesBox!.clear();
        await _articlesBox!.addAll(articles);
      }
      return articles;
    } catch (e) {
      if (_articlesBox != null &&
          _articlesBox!.isNotEmpty &&
          category == null &&
          search == null &&
          featured == null) {
        return _articlesBox!.values.toList();
      }
      rethrow;
    }
  }

  Future<List<NewsCategory>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _categoriesBox != null && _categoriesBox!.isNotEmpty) {
      return _categoriesBox!.values.toList();
    }

    try {
      final response = await _apiService.getCategories();
      final categories = response.data ?? [];
      if (_categoriesBox != null) {
        await _categoriesBox!.clear();
        await _categoriesBox!.addAll(categories);
      }
      return categories;
    } catch (e) {
      if (_categoriesBox != null && _categoriesBox!.isNotEmpty) {
        return _categoriesBox!.values.toList();
      }
      rethrow;
    }
  }

  Future<NewsArticle> getArticle(int id) async {
    try {
      final response = await _apiService.getArticle(id);
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleLike(int id) async {
    final response = await _apiService.toggleLike(id);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> toggleBookmark(int id) async {
    final response = await _apiService.toggleBookmark(id);
    return response.data ?? {};
  }

  Future<List<NewsArticle>> getBookmarks() async {
    final response = await _apiService.getBookmarks();
    return response.data ?? [];
  }

  Future<List<NewsComment>> getComments(int newsId) async {
    final response = await _apiService.getComments(newsId);
    return response.data ?? [];
  }

  Future<NewsComment> addComment(int newsId, String content, {int? parentId}) async {
    final response = await _apiService.addComment(newsId, content, parentId: parentId);
    return response.data!;
  }

  Future<void> deleteComment(int commentId) async {
    await _apiService.deleteComment(commentId);
  }

  Future<Map<String, dynamic>> share(int newsId, {String? platform}) async {
    final response = await _apiService.share(newsId, platform: platform);
    return response.data ?? {};
  }

  Future<List<NewsArticle>> getShorts() async {
    final response = await _apiService.getShorts();
    return response.data ?? [];
  }
}
