# 2016-12-12
# vagrant ssh -c "rails generate migration AddTrialPeriodColumn"
# vagrant ssh -c "bundle exec rake db:migrate"
class AddTrialPeriodColumn < ActiveRecord::Migration
	def change
		add_column :df_paid_membership_invoices, :trial_period,
			:integer, default: 0, null: false, :after => :currency
	end
end
