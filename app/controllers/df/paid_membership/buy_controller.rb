module ::Df::PaidMembership class BuyController < BaseController
	protect_from_forgery
	def index
		log 'BEGIN PURCHASE', params
		paymentRequestParams = {
			:action => 'Sale',
			:currency_code => currency,
			:description => %Q[Membership: #{plan['title']}, @#{user.username}, #{invoice.tier_label}],
			:quantity => 1,
			:amount => price,
			:notify_url => "#{Discourse.base_url}/plans/ipn",
			:invoice_number => invoice.id
		}
		log 'SetExpressCheckout REQUEST', paymentRequestParams
		payment_request = Paypal::Payment::Request.new paymentRequestParams
# https://developer.paypal.com/docs/classic/express-checkout/gs_expresscheckout/
# https://developer.paypal.com/docs/classic/api/merchant/SetExpressCheckout_API_Operation_NVP/
		response = paypal_express_request.setup(
			payment_request,
			# после успешной оплаты
			# покупатель будет перенаправлен на свою личную страницу
			"#{Discourse.base_url}/plans/success",
			# в случае неупеха оплаты
			# покупатель будет перенаправлен обратно на страницу с тарифными планами
			"#{Discourse.base_url}/plans",
			paypal_options
		)
		log 'SetExpressCheckout RESPONSE', {redirect_uri: response.redirect_uri}
		render json: { redirect_uri: response.redirect_uri }
	end
	protected
	# @override
	def invoice
		return @invoice if defined? @invoice
		@invoice = begin
			result = Invoice.new
			result.user = user
			result.plan_id = planId
			result.tier_id = tierId
			result.tier_period = tier['period']
			result.tier_period_units = tier['periodUnits']
			result.price = price
			result.currency = currency
			result.granted_group_ids = plan['grantedGroupIds'].join(',')
			result.payment_method = 'PayPal'
			result.save
			log 'INVOICE created', result.attributes
			result
		end
	end
	# 2015-08-30
	# @override
	# Не кэшируем результат, потому что invoice может сначала не существовать,
	# а потом существовать.
	def log_prefix
		result = super
		if @invoice
			result += "[#{@invoice.id}] "
		end
		result
	end
	private
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
			result = {
				:action => 'Sale',
				:currency_code => currency,
				:description => %Q[Membership: #{plan['title']}, @#{user.username}, #{invoice.tier_label}],
				:quantity => 1,
				:amount => price,
				:notify_url => "#{Discourse.base_url}/plans/ipn",
				:invoice_number => invoice.id
			}
			log 'SetExpressCheckout REQUEST', paypal_request_params
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
	def user
		return @user if defined? @user
		@user = User.find_by(id: params['user'])
	end
end end