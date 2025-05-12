import 'package:dio/dio.dart';
import 'package:hubster_app/core/api/api_client.dart';
import 'package:hubster_app/models/catalog/subscription_service.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/models/subscriptions/subscription_membership.dart';
import 'package:hubster_app/models/subscriptions/join_request.dart';
import 'package:injectable/injectable.dart';

// Service class for interacting with subscription-related backend APIs
@lazySingleton
class SubscriptionApiService {
  final ApiClient _apiClient;

  SubscriptionApiService(this._apiClient);

  // Fetches the list of predefined subscription services
  Future<List<SubscriptionService>> getSubscriptionServices() async {
    print("SubscriptionApiService: Fetching subscription services catalogue");
    try {
      final response = await _apiClient.dio.get('/subscription-services');
      final List<dynamic> serviceListJson = response.data as List<dynamic>;
      return serviceListJson
          .map(
            (json) =>
                SubscriptionService.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: getSubscriptionServices failed - ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch subscription services',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: getSubscriptionServices unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Creates a new hosted subscription offer by the current user
  Future<HostedSubscriptionResponse> createHostedSubscription(
    CreateHostedSubscriptionRequest request,
  ) async {
    print(
      "SubscriptionApiService: Creating hosted subscription - ${request.subscriptionTitle}",
    );
    try {
      final response = await _apiClient.dio.post(
        '/hosted-subscriptions',
        data: request.toJson(),
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        print(
          "FLUTTER RAW RESPONSE DATA KEYS for createHostedSubscription: ${responseData.keys.toList()}",
        );
        print(
          "FLUTTER RAW RESPONSE DATA VALUES for createHostedSubscription: ${responseData.values.toList()}",
        );
        responseData.forEach((key, value) {
          print(
            "FLUTTER JSON - Key: $key, Value: $value, ValueType: ${value.runtimeType}",
          );
        });
      }
      return HostedSubscriptionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: createHostedSubscription failed - ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to create hosted subscription',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: createHostedSubscription unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Fetches subscriptions hosted by the current user
  Future<List<HostedSubscriptionResponse>> getMyHostedSubscriptions() async {
    print("SubscriptionApiService: Fetching MY hosted subscriptions");
    try {
      final response = await _apiClient.dio.get(
        '/users/me/hosted-subscriptions',
      );
      final List<dynamic> listJson = response.data as List<dynamic>;
      return listJson
          .map(
            (json) => HostedSubscriptionResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: getMyHostedSubscriptions failed - ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ??
            'Failed to fetch your hosted subscriptions',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: getMyHostedSubscriptions unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Fetches subscriptions the current user is a member of
  Future<List<SubscriptionMembershipResponse>>
  getMyMemberSubscriptions() async {
    print("SubscriptionApiService: Fetching MY member subscriptions");
    try {
      final response = await _apiClient.dio.get('/users/me/memberships');
      final List<dynamic> listJson = response.data as List<dynamic>;
      return listJson
          .map(
            (json) => SubscriptionMembershipResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: getMyMemberSubscriptions failed - ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ??
            'Failed to fetch your member subscriptions',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: getMyMemberSubscriptions unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Fetches all publicly available hosted subscriptions for exploration
  Future<List<HostedSubscriptionResponse>> exploreSubscriptions({
    String? searchTerm,
    int? subscriptionServiceId,
    String? sortBy,
  }) async {
    print(
      "SubscriptionApiService: Exploring subscriptions. Search: $searchTerm, ServiceID: $subscriptionServiceId, SortBy: $sortBy",
    );
    try {
      Map<String, dynamic> queryParameters = {};
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParameters['search'] = searchTerm;
      }
      if (subscriptionServiceId != null && subscriptionServiceId > 0) {
        queryParameters['subscription_service_id'] =
            subscriptionServiceId.toString();
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParameters['sort_by'] = sortBy;
      }

      final response = await _apiClient.dio.get(
        '/hosted-subscriptions',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      // Backend returns a direct list now, not a paginated object
      final List<dynamic> listJson = response.data as List<dynamic>;
      return listJson
          .map(
            (json) => HostedSubscriptionResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: exploreSubscriptions failed - ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to explore subscriptions',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: exploreSubscriptions unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Fetches details of a single hosted subscription by its ID
  Future<HostedSubscriptionResponse> getHostedSubscriptionDetails(
    String id,
  ) async {
    print(
      "SubscriptionApiService: Fetching details for hosted subscription ID: $id",
    );
    try {
      final response = await _apiClient.dio.get('/hosted-subscriptions/$id');
      return HostedSubscriptionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: getHostedSubscriptionDetails failed for ID $id - ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch subscription details',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: getHostedSubscriptionDetails for ID $id unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Placeholder for requestToJoin - will be defined later
  Future<JoinRequest> requestToJoin(String hostedSubscriptionId) async {
    print("SubscriptionApiService: Requesting to join $hostedSubscriptionId");
    try {
      final response = await _apiClient.dio.post(
        '/hosted-subscriptions/$hostedSubscriptionId/join-requests',
      );
      return JoinRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: requestToJoin failed - ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to send join request',
      );
    } catch (e) {
      print("SubscriptionApiService: requestToJoin unexpected error - $e");
      throw Exception('An unexpected error occurred');
    }
  }

  // Fetches members of a specific hosted subscription
  Future<List<SubscriptionMembershipResponse>> getSubscriptionMembers(
    String hostedSubscriptionId,
  ) async {
    print(
      "SubscriptionApiService: Fetching members for hs ID: $hostedSubscriptionId",
    );
    try {
      final response = await _apiClient.dio.get(
        '/hosted-subscriptions/$hostedSubscriptionId/members',
      );
      final List<dynamic> listJson = response.data as List<dynamic>;
      return listJson
          .map(
            (json) => SubscriptionMembershipResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: getSubscriptionMembers failed for ID $hostedSubscriptionId - ${e.response?.statusCode}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch subscription members',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: getSubscriptionMembers for ID $hostedSubscriptionId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Fetches join requests for a specific hosted subscription
  Future<List<JoinRequest>> getJoinRequestsForSubscription(
    String hostedSubscriptionId, {
    String? status = "Pending",
  }) async {
    print(
      "SubscriptionApiService: Fetching join requests for hs ID: $hostedSubscriptionId, Status: $status",
    );
    try {
      Map<String, dynamic> queryParameters = {};
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      final response = await _apiClient.dio.get(
        '/hosted-subscriptions/$hostedSubscriptionId/join-requests',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      final List<dynamic> listJson = response.data as List<dynamic>;
      return listJson
          .map((json) => JoinRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: getJoinRequests failed for ID $hostedSubscriptionId - ${e.response?.statusCode}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch join requests',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: getJoinRequests for ID $hostedSubscriptionId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Approves a join request.
  Future<SubscriptionMembershipResponse> approveJoinRequest(
    String requestId,
  ) async {
    print("SubscriptionApiService: Approving join request ID: $requestId");
    try {
      final response = await _apiClient.dio.patch(
        '/join-requests/$requestId/approve',
      );
      // Backend returns the newly created SubscriptionMembership on approval
      return SubscriptionMembershipResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: approveJoinRequest failed for ID $requestId - ${e.response?.statusCode}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to approve join request',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: approveJoinRequest for ID $requestId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  // Declines a join request.
  Future<void> declineJoinRequest(String requestId) async {
    print("SubscriptionApiService: Declining join request ID: $requestId");
    try {
      await _apiClient.dio.patch('/join-requests/$requestId/decline');
      // Typically returns 200 OK with a message or just 204 No Content if successful
    } on DioException catch (e) {
      print(
        "SubscriptionApiService: declineJoinRequest failed for ID $requestId - ${e.response?.statusCode}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to decline join request',
      );
    } catch (e) {
      print(
        "SubscriptionApiService: declineJoinRequest for ID $requestId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }
}
