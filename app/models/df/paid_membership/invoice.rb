module ::Df::PaidMembership
	class Invoice < ActiveRecord::Base
		# psql --port=15432 -c "TRUNCATE df_paid_membership_invoices"
		self.table_name = 'df_paid_membership_invoices'
		belongs_to :user
		validates :user_id, presence: true
		def description
			return @description if defined? @description
			@description = %Q[#{plan_title}, #{tier_label}, @#{user.username}]
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
