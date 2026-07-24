
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/reminder_model.dart';

class RemindersApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<Reminder>>> getReminders() async {
    return await _apiClient.get(
      '/reminders',
      fromJsonT: (json) => (json as List)
          .map((item) => Reminder.fromJson(item))
          .toList(),
    );
  }

  Future<ApiResponse<Reminder>> createReminder(Map<String, dynamic> data) async {
    return await _apiClient.post(
      '/reminders',
      data: data,
      fromJsonT: (json) => Reminder.fromJson(json),
    );
  }

  Future<ApiResponse<Reminder>> updateReminder(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _apiClient.put(
      '/reminders/$id',
      data: data,
      fromJsonT: (json) => Reminder.fromJson(json),
    );
  }

  Future<ApiResponse<void>> deleteReminder(int id) async {
    return await _apiClient.delete('/reminders/$id');
  }
}
