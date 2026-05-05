import 'api_client.dart';
import '../models/test_model.dart';
import '../models/leaderboard.dart';
import '../models/vocabulary.dart';
import '../models/shop_item.dart';
import '../models/achievement.dart';
import '../models/notification.dart';

class StudentApi {
  final _client = ApiClient.instance;

  Future<Map<String, dynamic>> getProfile() async =>
      await _client.get('/gamification/profile/') as Map<String, dynamic>;

  Future<List<Achievement>> getAchievements() async {
    final data = await _client.get('/gamification/achievements/');
    final list = (data is Map ? data['results'] : data) as List? ?? [];
    return list
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TestModel>> getTestCatalog(
      {String? bookId, String? search}) async {
    final data = await _client.get('/tests/catalog/', params: {
      if (bookId != null) 'book': bookId,
      if (search != null && search.isNotEmpty) 'search': search,
    }) as Map<String, dynamic>;
    final list = data['results'] as List? ?? [];
    return list
        .map((e) => TestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    final data = await _client.get('/tests/books/');
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getTestDetail(String id) async =>
      await _client.get('/tests/$id/') as Map<String, dynamic>;

  Future<TestResultModel> submitTest(
      String testId, Map<String, int> answers) async {
    final payload = {
      'answers': answers.entries
          .map((e) => {'question': e.key, 'selected_option': e.value})
          .toList(),
    };
    final data = await _client.post(
      '/tests/$testId/submit/',
      data: payload,
    ) as Map<String, dynamic>;
    return TestResultModel.fromJson(data);
  }

  Future<TestResultModel> getAttemptResult(String attemptId) async {
    final data = await _client.get('/attempts/$attemptId/result/')
        as Map<String, dynamic>;
    return TestResultModel.fromJson(data);
  }

  Future<List<LeaderboardEntry>> getLeaderboard(
      {String scope = 'global'}) async {
    final data = await _client.get('/leaderboard/', params: {'scope': scope});
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VocabularyTopic>> getVocabularyTopics({String? bookId}) async {
    final data = await _client.get('/vocabulary/topics/', params: {
      if (bookId != null) 'book_id': bookId,
    });
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list
        .map((e) => VocabularyTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VocabularyWord>> getVocabularyWords(String topicId) async {
    final data = await _client.get('/vocabulary/topics/$topicId/words/');
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list
        .map((e) => VocabularyWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getWallet() async =>
      await _client.get('/coins/wallet/') as Map<String, dynamic>;

  Future<List<ShopItem>> getShopItems({String? category}) async {
    final data = await _client.get('/shop/items/', params: {
      if (category != null) 'category': category,
    });
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list
        .map((e) => ShopItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> purchaseItem(String slug) async =>
      await _client.post('/shop/items/$slug/purchase/', data: {})
          as Map<String, dynamic>;

  Future<List<Purchase>> getPurchases() async {
    final data = await _client.get('/shop/purchases/');
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list
        .map((e) => Purchase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getHomework() async =>
      await _client.get('/homework/') as Map<String, dynamic>;

  Future<List<AppNotification>> getNotifications() async {
    final data = await _client.get('/notifications/');
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getUnreadCount() async =>
      await _client.get('/notifications/unread-count/') as Map<String, dynamic>;

  Future<Map<String, dynamic>> getJourney() async =>
      await _client.get('/journey/me/') as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> getChallenges() async {
    final data = await _client.get('/challenges/current/');
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
