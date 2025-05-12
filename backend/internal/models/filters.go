package models

// ExploreSubscriptionFilters defines parameters for filtering hosted subscriptions.
type ExploreSubscriptionFilters struct {
	SearchTerm            *string `query:"search"`
	SubscriptionServiceID *uint   `query:"subscription_service_id"`
}
