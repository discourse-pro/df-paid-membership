// Admin-only initializer.
Discourse.initializer(
	require('discourse/plugins/df-paid-membership/admin/i', null, null, true).default
);