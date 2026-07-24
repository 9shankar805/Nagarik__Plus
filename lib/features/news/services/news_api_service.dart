import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/news_article.dart';
import '../models/news_category.dart';
import '../models/news_comment.dart';

class NewsApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<NewsArticle>>> getNews({
    String? category,
    String? search,
    bool? featured,
    int? page,
  }) async {
    final params = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category != 'All' && category != 'सबै') {
      params['category'] = category;
    }
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (featured != null) params['featured'] = featured;
    if (page != null) params['page'] = page;

    return await _apiClient.get(
      '/news',
      queryParameters: params,
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? (json['data'] is Map && json['data']['data'] != null
                ? json['data']['data'] as List
                : (json['data'] is List ? json['data'] as List : []))
            : (json is List ? json : []);
        return rawList
            .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<List<NewsCategory>>> getCategories() async {
    return await _apiClient.get(
      '/news/categories',
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? json['data'] as List
            : (json is List ? json : []);
        return rawList
            .map((item) => NewsCategory.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<NewsArticle>> getArticle(int id) async {
    return await _apiClient.get(
      '/news/$id',
      fromJsonT: (json) {
        final data = json is Map && json['data'] != null ? json['data'] : json;
        return NewsArticle.fromJson(data as Map<String, dynamic>);
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> toggleLike(int id) async {
    return await _apiClient.post(
      '/news/$id/like',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> toggleBookmark(int id) async {
    return await _apiClient.post(
      '/news/$id/bookmark',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<List<NewsArticle>>> getBookmarks() async {
    return await _apiClient.get(
      '/news/bookmarks',
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? (json['data'] is Map && json['data']['data'] != null
                ? json['data']['data'] as List
                : (json['data'] is List ? json['data'] as List : []))
            : (json is List ? json : []);
        return rawList
            .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<List<NewsComment>>> getComments(int newsId) async {
    return await _apiClient.get(
      '/news/$newsId/comments',
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? (json['data'] is Map && json['data']['data'] != null
                ? json['data']['data'] as List
                : (json['data'] is List ? json['data'] as List : []))
            : (json is List ? json : []);
        return rawList
            .map((item) => NewsComment.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<NewsComment>> addComment(int newsId, String content, {int? parentId}) async {
    return await _apiClient.post(
      '/news/$newsId/comments',
      data: {'content': content, if (parentId != null) 'parent_id': parentId},
      fromJsonT: (json) {
        final data = json is Map && json['data'] != null
            ? (json['data']['comment'] ?? json['data'])
            : json;
        return NewsComment.fromJson(data as Map<String, dynamic>);
      },
    );
  }

  Future<ApiResponse<void>> deleteComment(int commentId) async {
    return await _apiClient.delete(
      '/news/comments/$commentId',
      fromJsonT: (_) => null,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> share(int newsId, {String? platform}) async {
    return await _apiClient.post(
      '/news/$newsId/share',
      data: {'platform': platform ?? 'general'},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<List<NewsArticle>>> getShorts() async {
    return await _apiClient.get(
      '/news/shorts',
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? (json['data'] is Map && json['data']['data'] != null
                ? json['data']['data'] as List
                : (json['data'] is List ? json['data'] as List : []))
            : (json is List ? json : []);
        return rawList
            .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
