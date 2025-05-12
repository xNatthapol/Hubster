import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/catalog/subscription_service.dart';
import 'package:hubster_app/viewmodels/explore_subscriptions_notifier.dart';
import 'package:hubster_app/views/screens/home_screen.dart';
import 'subscription_detail_screen_join.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  String? _selectedSortBy;

  // Define sort options
  final Map<String, String> _sortOptions = {
    "created_at_desc": "Newest First",
    "cost_asc": "Price: Low to High",
    "cost_desc": "Price: High to Low",
    "name_asc": "Name: A-Z",
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {});
    _selectedSortBy =
        ref.read(exploreSubscriptionsNotifierProvider).currentSortBy;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String searchTerm) {
    ref
        .read(exploreSubscriptionsNotifierProvider.notifier)
        .setSearchTerm(searchTerm.trim());
  }

  void _onServiceFilterTapped(SubscriptionService? service) {
    // If tapping the same service that is already selected, clear the filter
    final currentSelectedId =
        ref.read(exploreSubscriptionsNotifierProvider).selectedServiceId;
    if (service != null && service.id == currentSelectedId) {
      ref
          .read(exploreSubscriptionsNotifierProvider.notifier)
          .setSelectedService(null);
    } else {
      ref
          .read(exploreSubscriptionsNotifierProvider.notifier)
          .setSelectedService(service);
    }
  }

  void _onSortByChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedSortBy = newValue;
      });
      ref
          .read(exploreSubscriptionsNotifierProvider.notifier)
          .setSortBy(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreSubscriptionsNotifierProvider);
    final notifier = ref.read(exploreSubscriptionsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Subscriptions"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search subscriptions...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
              onSubmitted: _onSearchSubmitted,
              onChanged: (value) {},
            ),
          ),

          // Filter Chips for Services
          if (state.availableServices.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                scrollDirection: Axis.horizontal,
                itemCount: state.availableServices.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All" filter chip
                    return ChoiceChip(
                      label: const Text("All"),
                      selected: state.selectedServiceId == null,
                      onSelected: (selected) => _onServiceFilterTapped(null),
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color:
                            state.selectedServiceId == null
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                      ),
                    );
                  }
                  final service = state.availableServices[index - 1];
                  return ChoiceChip(
                    avatar:
                        service.logoUrl != null && service.logoUrl!.isNotEmpty
                            ? CircleAvatar(
                              backgroundImage: NetworkImage(service.logoUrl!),
                              radius: 10,
                              backgroundColor: Colors.transparent,
                            )
                            : null,
                    label: Text(service.name),
                    selected: state.selectedServiceId == service.id,
                    onSelected: (selected) => _onServiceFilterTapped(service),
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color:
                          state.selectedServiceId == service.id
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
              ),
            ),

          // Sort By Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Sort by: ", style: Theme.of(context).textTheme.bodySmall),
                DropdownButton<String>(
                  value: _selectedSortBy ?? state.currentSortBy,
                  hint: const Text("Default"),
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  elevation: 2,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                  underline: Container(
                    height: 1,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  items:
                      _sortOptions.entries.map<DropdownMenuItem<String>>((
                        entry,
                      ) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                  onChanged: _onSortByChanged,
                ),
              ],
            ),
          ),

          // List of Subscriptions
          Expanded(
            child:
                state.isLoading && state.subscriptions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.errorMessage != null && state.subscriptions.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("Error: ${state.errorMessage}"),
                      ),
                    )
                    : state.subscriptions.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "No subscriptions found matching your criteria.",
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async {
                        await notifier.fetchSubscriptions(resetLoading: false);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 12.0,
                          right: 12.0,
                          bottom: 12.0,
                          top: 0,
                        ),
                        itemCount: state.subscriptions.length,
                        itemBuilder: (context, index) {
                          final sub = state.subscriptions[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => SubscriptionDetailScreenJoin(
                                        subscriptionId: sub.id.toString(),
                                      ),
                                ),
                              );
                            },
                            child: HostedSubscriptionCard(subscription: sub),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
