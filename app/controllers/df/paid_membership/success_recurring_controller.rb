# https://developer.paypal.com/webapps/developer/docs/classic/products/#recurring
# https://developer.paypal.com/webapps/developer/docs/classic/paypal-payments-pro/integration-guide/WPRecurringPayments/
# https://developer.paypal.com/webapps/developer/docs/classic/express-checkout/integration-guide/ECRecurringPayments/
module ::Df::PaidMembership class SuccessRecurringController < SuccessController
	protected
	# @override
	def confirm_payment
		raise unless 'ActiveProfile' === subscription_response.recurring.status
	end
	# @override
	def invoice
		return @invoice if defined? @invoice
		# http://stackoverflow.com/a/25274645
		@invoice = Invoice.where(user_id: user.id,  paid_at: nil).last
	end
	# @override
	def invoiceId
		invoice.id
	end
	# @override
	def update_invoice
		super
		invoice.recurring_profile_id = subscription_response.recurring.identifier
	end
	private
	def subscription_request_params
		return @subscription_request_params if defined? @subscription_request_params
		@subscription_request_params = Paypal::Payment::Recurring.new(
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BNA01I0E9__idd4198f0a-9b54-4cb2-90e9-2c7b4fdd0324
			:billing => {
				# AMT
				:amount => invoice.price,
				# CURRENCYCODE
				:currency_code => invoice.currency,
				# BILLINGFREQUENCY
				:frequency => invoice.tier_period,
				# BILLINGPERIOD
				:period => invoice.paypal_billing_period,
				:trial => {
					:period => :Day,
					:frequency => trialPeriod,
					:total_cycles => 1,
					:amount => 0
				}
			},
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BN9L00JPN__id156e9ad4-5e4d-463a-98fa-b34e350a1886
			# DESC
			:description => invoice.description,
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BNA100BE6__id7bd11dfe-c599-4af2-aea0-cdea481bad4b
			# SUBSCRIBERNAME
			:name => user.name.empty? ? user.username : user.name,
			# PROFILEREFERENCE
			:reference => invoice.id,
			# PROFILESTARTDATE
			:start_date => invoice.created_at
		)
	end
	def subscription_response
		return @subscription_response if defined? @subscription_response
		@subscription_response = begin
			log 'CreateRecurringPaymentsProfile REQUEST', subscription_request_params
			# https://github.com/nov/paypal-express/wiki/Recurring-Payment#create-recurring-profile
			result = paypal_express_request.subscribe!(token, subscription_request_params)
			log 'CreateRecurringPaymentsProfile RESPONSE', result
			result
		end
	end
end end