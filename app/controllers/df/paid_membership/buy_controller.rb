module ::Df::PaidMembership class BuyController < BaseController
	protect_from_forgery
	def index
		log 'BEGIN PURCHASE', params
		render json: {redirect_uri: paypal_response.redirect_uri}
	end
	protected
	# @override
	def invoiceId
		# http://stackoverflow.com/a/28651525
		@invoice ? @invoice.id : super
	end
	private
	def invoice
		return @invoice if defined? @invoice
		@invoice = begin
			result = Invoice.new
			result.user = user
			result.plan_id = planId
			result.plan_title = plan['title']
			result.tier_id = tierId
			result.tier_period = tier['period']
			result.tier_period_units = tier['periodUnits']
			result.price = price
			result.currency = currency
			result.granted_group_ids = plan['grantedGroupIds'].join(',')
			result.payment_method = 'PayPal'
			result.save
			log 'INVOICE created', result
			result
		end
	end
	def paypal_options
		{
			no_shipping: true, # if you want to disable shipping information
			allow_note: false, # if you want to disable notes
			pay_on_paypal: true # if you don't plan on showing your own confirmation step
		}
	end
	def paypal_request_params
		return @paypal_request_params if defined? @paypal_request_params
		@paypal_request_params = begin
			if recurring?
				# https://github.com/nov/paypal-express/wiki/Recurring-Payment#setup-transaction
				result = {
					:currency_code => currency,
					:billing_type  => :RecurringPayments,
					:billing_agreement_description => invoice.description
				}
			else
				result = {
					:action => 'Sale',
					:currency_code => currency,
					:description => invoice.description,
					:quantity => 1,
					:amount => price,
					:notify_url => "#{Discourse.base_url}/plans/ipn",
					:invoice_number => invoice.id
				}
			end
			log 'SetExpressCheckout REQUEST', result
			result
		end
	end
	def paypal_response
		return @paypal_response if defined? @paypal_response
		@paypal_response = begin
	# https://developer.paypal.com/docs/classic/express-checkout/gs_expresscheckout/
	# https://developer.paypal.com/docs/classic/api/merchant/SetExpressCheckout_API_Operation_NVP/
			result = paypal_express_request.setup(
				Paypal::Payment::Request.new(paypal_request_params),
				# после успешной оплаты
				# покупатель будет перенаправлен на свою личную страницу
				"#{Discourse.base_url}/plans/success",
				# в случае неупеха оплаты
				# покупатель будет перенаправлен обратно на страницу с тарифными планами
				"#{Discourse.base_url}/plans",
				paypal_options
			)
			log 'SetExpressCheckout RESPONSE', {redirect_uri: result.redirect_uri}
			result
		end
	end
	def plan
		return @plan if defined? @plan
		@plan = begin
			result = nil
			plans.each { |p|
				if planId == p['id']
					result = p
					break
				end
			}
			result
		end
	end
	def plans
		return @plans if defined? @plans
		@plans = begin
			JSON.parse(SiteSetting.send '«Paid_Membership»_Plans')
		rescue JSON::ParserError => e
			[]
		end
	end
	def planId
		params['plan']
	end
	def price
		tier['price']
	end
	def tier
		return @tier if defined? @tier
		@tier = begin
			result = nil
			plan['priceTiers'].each { |t|
				if tierId == t['id']
					result = t
					break
				end
			}
			result
		end
	end
	def tierId
		params['tier']
	end
end end