module ::Df::PaidMembership
	class Invoice < ActiveRecord::Base
		# psql --port=15432 -c "TRUNCATE df_paid_membership_invoices"
		self.table_name = 'df_paid_membership_invoices'
		belongs_to :user
		validates :user_id, presence: true
=begin
2016-12-18
Описание подписки должно быть идентичным в запросе SetExpressCheckout
и в последующем запросе CreateRecurringPaymentsProfile.

Также у описания присутствуют ограничения:
1) Required
2) Character length and limitations: 127 single-byte alphanumeric characters
https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#schedule-details-fields
https://github.com/discourse-pro/df-paid-membership/issues/9

Что интересно, в примере официальной документации используется символ точки:
«For example, buyer is billed at "9.99 per month for 2 years".»
https://developer.paypal.com/docs/classic/api/merchant/SetExpressCheckout_API_Operation_NVP/#billing-agreement-details-type-fields
=end
		# @return [String]
		def description
			return @description if defined? @description
			# http://stackoverflow.com/a/6104247
			@description = %Q[#{plan_title}, #{tier_label}, @#{user.username}][0,127]
		end
		# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BNA01I0E9__idd4198f0a-9b54-4cb2-90e9-2c7b4fdd0324
		def paypal_billing_period
			case tier_period_units
				when 'y'
					result = :Year
				when 'm'
					result = :Month
				when 'd'
					result = :Day
			end
			result
		end
		private
		def tier_label
			case tier_period_units
				when 'y'
					unitsLabel = 'year'
				when 'm'
					unitsLabel = 'month'
				when 'd'
					unitsLabel = 'day'
			end
			if 1 < tier_period
				unitsLabel += 's'
			end
			%Q[#{tier_period} #{unitsLabel}]
		end
		# == Schema Information
		#
		# Table name: df_paid_membership_invoices
		#
		#  id :integer not null, primary key
		#  user_id :integer not null
		#  plan_id :string(7) not null
		#  tier_id :string(7) not null
		#  tier_period :integer not null
		#  tier_period_units :string(1) not null
		#  price :float not null
		#  currency :string(3) not null
		#  created_at :datetime not null
		#  updated_at :datetime not null
		#  paid_at :datetime
		#  membership_till :datetime
		#  granted_group_ids :string(255)
		#  payment_method :string(255)
		#  plan_title :string
		# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BN9G00NHT__id085U40N0XTS
		#  recurring_profile_id :string(14)
	end
end
