import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:Maya/core/services/storage_service.dart';
import '../constants/app_constants.dart';

final getIt = GetIt.instance;

class ApiClient {
  late final Dio _publicDio;
  late final Dio _protectedDio;

  ApiClient(Dio publicDio, Dio protectedDio) {
    _publicDio = publicDio;
    _protectedDio = protectedDio;

    // Configure public Dio instance
    _publicDio.options.baseUrl = AppConstants.baseUrl;
    _publicDio.options.connectTimeout = Duration(
      milliseconds: AppConstants.connectionTimeout,
    );
    _publicDio.options.receiveTimeout = Duration(
      milliseconds: AppConstants.receiveTimeout,
    );
    _publicDio.options.headers['Content-Type'] = 'application/json';

    // Configure protected Dio instance
    _protectedDio.options.baseUrl = AppConstants.protectedUrl;
    _protectedDio.options.connectTimeout = Duration(
      milliseconds: AppConstants.connectionTimeout,
    );
    _protectedDio.options.receiveTimeout = Duration(
      milliseconds: AppConstants.receiveTimeout,
    );
    _protectedDio.options.headers['Content-Type'] = 'application/json';

    // Add interceptors for both instances
    _publicDio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
    _protectedDio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

    // Add authorization interceptor for protected Dio
    _protectedDio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final token = await getIt<StorageService>().getAccessToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              return handler.next(options);
            },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // You can add token refresh logic here if needed
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(
    Dio dio,
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(Dio dio, String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(Dio dio, String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> delete(Dio dio, String path, {dynamic data}) async {
    return await dio.delete(path, data: data);
  }

  // Login API
  Future<Map<String, dynamic>> login(Map<String, dynamic> payload) async {
    final response = await post(_publicDio, '/auth/login', data: payload);
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  Map<String, dynamic> prepareLoginPayload(String email, String password) {
    return {'email': email, 'password': password};
  }

  // Google Sign-In API
  Future<Map<String, dynamic>> googleLogin(Map<String, dynamic> payload) async {
    final response = await post(_publicDio, '/auth/google/', data: payload);
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  Map<String, dynamic> prepareGoogleLoginPayload(String accessToken) {
    return {'access_token': accessToken};
  }

  // Refresh Token API
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await post(
      _publicDio,
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    print('refreshToken response: ${response.data}');
    print('refreshToken statusCode: ${response.statusCode}');
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  // Google Access Token Mobile API
  Future<Map<String, dynamic>> googleAccessTokenMobile(
    Map<String, dynamic> payload,
  ) async {
    final response = await post(
      _protectedDio,
      '/crm/google/access-token-mobile',
      data: payload,
    );
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  Map<String, dynamic> prepareGoogleAccessTokenMobilePayload(
    String accessToken,
    String refreshToken,
    String scope,
    String tokenType,
  ) {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'scope': scope,
      'token_type': tokenType,
    };
  }

  // Fetch Tasks API
  Future<Map<String, dynamic>> fetchTasks() async {
    final response = await get(
      _protectedDio,
      '/thunder/get-tool-call-sessions',
    );
    print('fetchTasks response: ${response.data}');
    print('fetchTasks statusCode: ${response.statusCode}');
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  // Fetch Tasks Detail API
  Future<Map<String, dynamic>> fetchTasksDetail({
    required String sessionId,
  }) async {
    final response = await get(
      _protectedDio,
      '/thunder/get-tool-calls/$sessionId',
    );
    print('fetchTasksDetail response: ${response.data}');
    print('fetchTasksDetail statusCode: ${response.statusCode}');
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  // Sync Contacts API
  Future<Map<String, dynamic>> syncContacts(
    List<Map<String, String>> payload,
  ) async {
    final response = await post(
      _publicDio,
      '/communication/sync-contacts',
      data: payload,
    );
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  List<Map<String, String>> prepareSyncContactsPayload(
    List<Map<String, String>> contactList,
  ) {
    return contactList;
  }

  // Start Thunder API
  Future<Map<String, dynamic>> startThunder(String agentType) async {
    final response = await post(
      _protectedDio,
      '/thunder/start-thunder',
      data: {'agent_type': agentType},
    );
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  Map<String, dynamic> prepareStartThunderPayload(String agentType) {
    return {'agent_type': agentType};
  }

  // Fetch Call Sessions API
  Future<Map<String, dynamic>> fetchCallSessions({int page = 1}) async {
    final response = await get(
      _protectedDio,
      '/thunder/get-sessions',
      queryParameters: {'page': page.toString()},
    );
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  // Create To-Do API
  Future<Map<String, dynamic>> createToDo(Map<String, dynamic> payload) async {
    final response = await post(
      _protectedDio,
      '/crm/todo/create',
      data: payload,
    );
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  Map<String, dynamic> prepareCreateToDoPayload(
    String title,
    String description,
    String? reminderTime,
  ) {
    return {
      'title': title,
      'description': description,
      'reminder': reminderTime != null && reminderTime.isNotEmpty,
      'reminder_time': reminderTime,
    };
  }

  // Get To-Do API
  Future<Map<String, dynamic>> getToDo() async {
    print('getToDo');
    final response = await get(_protectedDio, '/crm/todo/get');
    print('getToDo response: ${response.data}');
    print('getToDo statusCode: ${response.statusCode}');
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  // Update To-Do API
  Future<Map<String, dynamic>> updateToDo(Map<String, dynamic> payload) async {
    final response = await put(
      _protectedDio,
      '/crm/todo/update',
      data: payload,
    );
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  Map<String, dynamic> prepareUpdateToDoPayload(
    int id, {
    required String title,
    required String description,
    required String status,
    required bool reminder,
    String? reminder_time,
  }) {
    return {
      'ID': id,
      'title': title,
      'description': description,
      'status': status,
      'reminder': reminder,
      'reminder_time': reminder_time,
    };
  }

  // Delete To-Do API
  Future<Map<String, dynamic>> deleteToDo(int id) async {
    final response = await delete(
      _protectedDio,
      '/crm/todo/delete',
      data: {'ID': id},
    );
    return {'statusCode': response.statusCode, 'data': response.data};
  }

  Map<String, dynamic> prepareDeleteToDoPayload(int id) {
    return {'ID': id};
  }
}
