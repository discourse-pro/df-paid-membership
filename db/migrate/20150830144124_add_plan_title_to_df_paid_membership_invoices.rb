# rails generate migration AddPlanTitleToDfPaidMembershipInvoices
# rake db:migrate:redo VERSION=20150830144124
class AddPlanTitleToDfPaidMembershipInvoices < ActiveRecord::Migration
	def change
		# http://stackoverflow.com/a/3251000
		add_column :df_paid_membership_invoices, :plan_title, :string, :after => :plan_id
	end
end