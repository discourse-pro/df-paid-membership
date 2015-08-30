module ::Df::PaidMembership class SuccessSimpleController < SuccessController
	protected
	# @override
	def confirm_payment
		requestParams = {
			:action => 'Sale',
			:currency_code => invoice.currency,
			:amount => details.amount
		}
		log 'DoExpressCheckoutPayment REQUEST', requestParams
# https://developer.paypal.com/docs/classic/api/merchant/DoExpressCheckoutPayment_API_Operation_NVP/
# https://gist.github.com/xcommerce-gists/3502241
		response = paypal_express_request.checkout!(
			params['token'],
			params['PayerID'],
			Paypal::Payment::Request.new(requestParams)
		)
		log 'DoExpressCheckoutPayment RESPONSE', response.instance_values
	end
	# @override
	def invoice
		return @invoice if defined? @invoice
		@invoice = Invoice.find_by id: details.invoice_number
	end
	# @override
	def invoiceId
		@details ? @details.invoice_number : super
	end
	private
	# https://developer.paypal.com/docs/classic/api/merchant/GetExpressCheckoutDetails_API_Operation_NVP/
	# https://github.com/nov/paypal-express/wiki/Instant-Payment
	def details
		return @details if defined? @details
		@details = begin
			log 'GetExpressCheckoutDetails REQUEST'
			result = paypal_express_request.details(token)
			log 'GetExpressCheckoutDetails RESPONSE', result.instance_values
			result
		end
	end
end end