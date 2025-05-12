import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'package:hubster_app/models/catalog/subscription_service.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/services/subscription_api_service.dart';
import 'package:equatable/equatable.dart';

// State for the Explore screen
class ExploreSubscriptionsState extends Equatable {
  final bool isLoading;
  final List<HostedSubscriptionResponse> subscriptions;
  final List<SubscriptionService> availableServices;
  final String? errorMessage;
  final String? searchTerm;
  final int? selectedServiceId;
  final String? currentSortBy;

  const ExploreSubscriptionsState({
    this.isLoading = true,
    this.subscriptions = const [],
    this.availableServices = const [],
    this.errorMessage,
    this.searchTerm,
    this.selectedServiceId,
    this.currentSortBy = "created_at_desc",
  });

  ExploreSubscriptionsState copyWith({
    bool? isLoading,
    List<HostedSubscriptionResponse>? subscriptions,
    List<SubscriptionService>? availableServices,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? searchTerm,
    bool clearSearchTerm = false,
    int? selectedServiceId,
    bool clearSelectedServiceId = false,
    String? currentSortBy,
  }) {
    return ExploreSubscriptionsState(
      isLoading: isLoading ?? this.isLoading,
      subscriptions: subscriptions ?? this.subscriptions,
      availableServices: availableServices ?? this.availableServices,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      searchTerm: clearSearchTerm ? null : searchTerm ?? this.searchTerm,
      selectedServiceId:
          clearSelectedServiceId
              ? null
              : selectedServiceId ?? this.selectedServiceId,
      currentSortBy: currentSortBy ?? this.currentSortBy,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    subscriptions,
    availableServices,
    errorMessage,
    searchTerm,
    selectedServiceId,
    currentSortBy,
  ];
}

// Notifier for ExploreSubscriptions
class ExploreSubscriptionsNotifier
    extends StateNotifier<ExploreSubscriptionsState> {
  final SubscriptionApiService _subscriptionApiService;

  ExploreSubscriptionsNotifier(this._subscriptionApiService)
    : super(const ExploreSubscriptionsState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchSubscriptionServices();
    await fetchSubscriptions();
  }

  Future<void> fetchSubscriptionServices() async {
    try {
      final services = await _subscriptionApiService.getSubscriptionServices();
      state = state.copyWith(availableServices: services);
    } catch (e) {
      print("ExploreSubscriptionsNotifier: Error fetching services: $e");
      state = state.copyWith(errorMessage: "Could not load filter services.");
    }
  }

  Future<void> fetchSubscriptions({bool resetLoading = true}) async {
    if (resetLoading) {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }
    try {
      final subs = await _subscriptionApiService.exploreSubscriptions(
        searchTerm: state.searchTerm,
        subscriptionServiceId: state.selectedServiceId,
        sortBy: state.currentSortBy,
      );
      state = state.copyWith(isLoading: false, subscriptions: subs);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchTerm(String? term) {
    state = state.copyWith(
      searchTerm: term,
      clearSearchTerm: term == null || term.isEmpty,
    );
    fetchSubscriptions();
  }

  void setSelectedService(SubscriptionService? service) {
    state = state.copyWith(
      selectedServiceId: service?.id,
      clearSelectedServiceId: service == null,
    );
    fetchSubscriptions();
  }

  void setSortBy(String? sortByValue) {
    state = state.copyWith(currentSortBy: sortByValue);
    fetchSubscriptions();
  }
}

final exploreSubscriptionsNotifierProvider = StateNotifierProvider<
  ExploreSubscriptionsNotifier,
  ExploreSubscriptionsState
>((ref) {
  return ExploreSubscriptionsNotifier(getIt<SubscriptionApiService>());
});
