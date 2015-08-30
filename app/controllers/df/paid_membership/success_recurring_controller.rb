module ::Df::PaidMembership class SuccessRecurringController < SuccessController
	protected
	# @override
	def confirm_payment
		log 'CreateRecurringPaymentsProfile REQUEST', subscription_request_params
		# https://github.com/nov/paypal-express/wiki/Recurring-Payment#create-recurring-profile
		response = paypal_express_request.subscribe!(token, subscription_request_params)
		log 'CreateRecurringPaymentsProfile RESPONSE', response.recurring
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
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BNA100BE6__id7bd11dfe-c599-4af2-aea0-cdea481bad4b
			# SUBSCRIBERNAME
			:name => user.name.empty? ? user.username : user.name,
			# PROFILESTARTDATE
			:start_date => invoice.created_at,
			# PROFILEREFERENCE
			:reference => invoice.id,
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BN9L00JPN__id156e9ad4-5e4d-463a-98fa-b34e350a1886
			# DESC
			:description => invoice.description,
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BNA01I0E9__idd4198f0a-9b54-4cb2-90e9-2c7b4fdd0324
			:billing => {
				# BILLINGPERIOD
				:period => invoice.paypal_billing_period,
				# BILLINGFREQUENCY
				:frequency => invoice.tier_period,
				# AMT
				:amount => invoice.price,
				# CURRENCYCODE
				:currency_code => invoice.currency
			}
		)
	end
	def subscription_response
		return @subscription_response if defined? @subscription_response
		@subscription_response = begin
			log 'CreateRecurringPaymentsProfile REQUEST', subscription_request_params
			# https://github.com/nov/paypal-express/wiki/Recurring-Payment#create-recurring-profile
			result = paypal_express_request.subscribe!(token, subscription_request_params)
			log 'CreateRecurringPaymentsProfile RESPONSE', response
		end
	end
end end