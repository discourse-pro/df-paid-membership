module Df
	module PaidMembership
		class Invoice < ActiveRecord::Base
			self.table_name = 'df_paid_membership_invoices'
			belongs_to :user
			validates :user_id, presence: true
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
			#  payed_at :datetime
			#  membership_till :datetime
			#  granted_group_ids :string(255)
			#  payment_method :string(255)
		end
	end
end
=begin
User.class_eval do
	has_many :paid_membership_invoices,
		dependent: :destroy,
		:class_name => 'Df::PaidMembership::Invoice',
		:foreign_key => 'df_paid_membership_invoice_id'
end
=end
