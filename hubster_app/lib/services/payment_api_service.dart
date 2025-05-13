import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hubster_app/core/api/api_client.dart';
import 'package:hubster_app/models/payment/payment_record.dart';
import 'package:injectable/injectable.dart';

// Service for handling payment related API calls.
@lazySingleton
class PaymentApiService {
  final ApiClient _apiClient;

  PaymentApiService(this._apiClient);

  // Fetches the payment history for a specific subscription membership.
  Future<List<PaymentRecordResponse>> getPaymentRecordsForMembership(
    String membershipId,
  ) async {
    print(
      "PaymentApiService: Fetching payment records for membership ID: $membershipId",
    );
    try {
      final response = await _apiClient.dio.get(
        '/memberships/$membershipId/payment-records',
      );
      final List<dynamic> listJson = response.data as List<dynamic>;
      return listJson
          .map(
            (json) =>
                PaymentRecordResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      print(
        "PaymentApiService: getPaymentRecordsForMembership failed for ID $membershipId - Status: ${e.response?.statusCode}, Data: ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch payment history',
      );
    } catch (e) {
      print(
        "PaymentApiService: getPaymentRecordsForMembership for ID $membershipId unexpected error - $e",
      );
      throw Exception(
        'An unexpected error occurred while fetching payment history',
      );
    }
  }

  // Submits payment proof for a specific membership.
  Future<PaymentRecordResponse> submitPaymentProof(
    String membershipId,
    CreatePaymentRecordRequest request,
  ) async {
    print(
      "PaymentApiService: Submitting payment proof for membership ID: $membershipId",
    );
    try {
      final response = await _apiClient.dio.post(
        '/memberships/$membershipId/payment-records',
        data: request.toJson(),
      );
      return PaymentRecordResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print(
        "PaymentApiService: submitPaymentProof failed for ID $membershipId - Status: ${e.response?.statusCode}, Data: ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to submit payment proof',
      );
    } catch (e) {
      print(
        "PaymentApiService: submitPaymentProof for ID $membershipId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred while submitting proof');
    }
  }

  Future<List<PaymentRecordResponse>> getPaymentRecordsForHostedSubscription(
    String hostedSubscriptionId, {
    String? status,
  }) async {
    print(
      "PaymentApiService: Fetching payment records for HS ID: $hostedSubscriptionId, Status: $status",
    );
    try {
      Map<String, dynamic> queryParameters = {};
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      final response = await _apiClient.dio.get(
        '/hosted-subscriptions/$hostedSubscriptionId/payment-records',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      final List<dynamic> listJson = response.data as List<dynamic>;
      if (listJson.isNotEmpty) {
        print(
          "FLUTTER RAW JSON for first payment record: ${jsonEncode(listJson[0])}",
        );
      }
      return listJson
          .map(
            (json) =>
                PaymentRecordResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      print(
        "PaymentApiService: getPaymentRecordsForHostedSubscription failed for ID $hostedSubscriptionId - ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch payment records for host',
      );
    } catch (e) {
      print(
        "PaymentApiService: getPaymentRecordsForHostedSubscription for ID $hostedSubscriptionId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  Future<PaymentRecordResponse> getPaymentRecordDetails(
    String paymentRecordId,
  ) async {
    print(
      "PaymentApiService: Fetching details for payment record ID: $paymentRecordId",
    );
    try {
      final response = await _apiClient.dio.get(
        '/payment-records/$paymentRecordId',
      );
      return PaymentRecordResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print(
        "PaymentApiService: getPaymentRecordDetails failed for ID $paymentRecordId - ${e.response?.statusCode}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch payment record details',
      );
    } catch (e) {
      print(
        "PaymentApiService: getPaymentRecordDetails for ID $paymentRecordId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  Future<PaymentRecordResponse> approvePaymentProof(
    String paymentRecordId, {
    String? notes,
  }) async {
    print("PaymentApiService: Approving payment record ID: $paymentRecordId");
    try {
      final Map<String, dynamic> data = {};
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }
      final response = await _apiClient.dio.patch(
        '/payment-records/$paymentRecordId/approve',
        data: data.isNotEmpty ? data : null,
      );
      return PaymentRecordResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print(
        "PaymentApiService: approvePaymentProof failed for ID $paymentRecordId - ${e.response?.statusCode}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to approve payment proof',
      );
    } catch (e) {
      print(
        "PaymentApiService: approvePaymentProof for ID $paymentRecordId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }

  Future<PaymentRecordResponse> declinePaymentProof(
    String paymentRecordId, {
    String? notes,
  }) async {
    print("PaymentApiService: Declining payment record ID: $paymentRecordId");
    try {
      final Map<String, dynamic> data = {};
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      } else {}
      final response = await _apiClient.dio.patch(
        '/payment-records/$paymentRecordId/decline',
        data: data,
      );
      return PaymentRecordResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print(
        "PaymentApiService: declinePaymentProof failed for ID $paymentRecordId - ${e.response?.statusCode}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to decline payment proof',
      );
    } catch (e) {
      print(
        "PaymentApiService: declinePaymentProof for ID $paymentRecordId unexpected error - $e",
      );
      throw Exception('An unexpected error occurred');
    }
  }
}
