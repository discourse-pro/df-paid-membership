# rails generate migration CreateDfPaidMembershipInvoices
class CreateDfPaidMembershipInvoices < ActiveRecord::Migration
	def change
		create_table :df_paid_membership_invoices do |t|
			t.integer :user_id, null: false
			t.string :plan_id, limit: 7, null: false
			t.string :tier_id, limit: 7, null: false
			t.integer :tier_period, null: false
			t.string :tier_period_units, limit: 1, null: false
			t.float :price, null: false
			t.string :currency, limit: 3, null: false
			t.timestamps
			t.datetime :paid_at
			t.datetime :membership_till
			t.string :granted_group_ids, limit: 255
			t.string :payment_method, limit: 255
		end
	end
end
