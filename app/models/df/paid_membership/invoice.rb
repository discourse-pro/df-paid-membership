module ::Df::PaidMembership
	class Invoice < ActiveRecord::Base
		# psql --port=15432 -c "TRUNCATE df_paid_membership_invoices"
		self.table_name = 'df_paid_membership_invoices'
		belongs_to :user
		validates :user_id, presence: true
		def tier_label
			case invoice.tier_period_units
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
		# Table name: paid_membership_invoices
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
	end
end
