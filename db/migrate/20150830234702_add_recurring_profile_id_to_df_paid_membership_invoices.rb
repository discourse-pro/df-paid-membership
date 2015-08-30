# rails generate migration AddRecurringProfileIdToDfPaidMembershipInvoices
# rake db:migrate:redo VERSION=20150830234702
class AddRecurringProfileIdToDfPaidMembershipInvoices < ActiveRecord::Migration
	def change
		# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BN9G00NHT__id085U40N0XTS
		add_column :df_paid_membership_invoices, :recurring_profile_id, :string, limit: 14
	end
end
