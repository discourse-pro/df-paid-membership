module ::Df::PaidMembership class SuccessRecurringController < SuccessController
	protected
	# @override
	def confirm_payment
		requestParams = {
			:action => 'Sale',
			:currency_code => invoice.currency,
			:amount => details.amount
		}
		log 'CreateRecurringPaymentsProfile REQUEST', requestParams
# https://developer.paypal.com/docs/classic/api/merchant/DoExpressCheckoutPayment_API_Operation_NVP/
# https://gist.github.com/xcommerce-gists/3502241
		response = paypal_express_request.checkout!(
			params['token'],
			params['PayerID'],
			Paypal::Payment::Request.new(requestParams)
		)
		log 'CreateRecurringPaymentsProfile RESPONSE', response.instance_values
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
end end