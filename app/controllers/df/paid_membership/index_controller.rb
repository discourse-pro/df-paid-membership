require_dependency 'application_controller'
module ::Df::PaidMembership
	class IndexController < ::ApplicationController
		skip_before_filter :authorize_mini_profiler,
			:check_xhr,
			:inject_preview_style,
			:preload_json,
			:redirect_to_login_if_required,
			:set_current_user_for_logs,
			:set_locale,
			:set_mobile_view,
			:verify_authenticity_token, only: [:ipn, :success]
		protect_from_forgery :except => [:ipn, :success]
		before_filter :paypal_set_sandbox_mode_if_needed, only: [:buy, :ipn, :success]
		def index
			begin
				plans = JSON.parse(SiteSetting.send '«Paid_Membership»_Plans')
			rescue JSON::ParserError => e
				plans = []
			end
			render json: { plans: plans }
		end
		def buy
			log 'BEGIN PURCHASE', params
			plans = JSON.parse(SiteSetting.send '«Paid_Membership»_Plans')
			plan = nil
			planId = params['plan']
			plans.each { |p|
				if planId == p['id']
					plan = p
					break
				end
			}
			tier = nil
			tierId = params['tier']
			plan['priceTiers'].each { |t|
				if tierId == t['id']
					tier = t
					break
				end
			}
			price = tier['price']
			currency = SiteSetting.send '«Money»_Currency'
			user = User.find_by(id: params['user'])
			# http://guides.rubyonrails.org/active_record_basics.html
			invoice = Invoice.new
			invoice.user = user
			invoice.plan_id = planId
			invoice.tier_id = tierId
			invoice.tier_period = tier['period']
			invoice.tier_period_units = tier['periodUnits']
			invoice.price = price
			invoice.currency = currency
			invoice.granted_group_ids = plan['grantedGroupIds'].join(',')
			invoice.payment_method = 'PayPal'
			invoice.save
			log 'INVOICE created', invoice.attributes
			paypal_options = {
				no_shipping: true, # if you want to disable shipping information
				allow_note: false, # if you want to disable notes
				pay_on_paypal: true # if you don't plan on showing your own confirmation step
			}
			description =
				%Q[Membership: #{plan['title']}, @#{user.username}, #{invoice.tier_label}]
			paymentRequestParams = {
				:action => 'Sale',
				:currency_code => currency,
				:description => description,
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
		def ipn
			no_cookies
			log 'IPN', params
			Paypal::IPN.verify!(request.raw_post)
			render :nothing => true
		end
		def success
			log 'CUSTOMER RETURNED', params
	# https://developer.paypal.com/docs/classic/api/merchant/GetExpressCheckoutDetails_API_Operation_NVP/
	# https://github.com/nov/paypal-express/wiki/Instant-Payment
			detailsRequest = paypal_express_request
			log 'GetExpressCheckoutDetails REQUEST'
			details = detailsRequest.details(params['token'])
			log 'GetExpressCheckoutDetails RESPONSE', details.instance_values
			invoice = Invoice.find_by(id: details.invoice_number)
			doExpressCheckoutPayment_params = {
				:action => 'Sale',
				:currency_code => invoice.currency,
				:amount => details.amount
			}
			log 'DoExpressCheckoutPayment REQUEST', doExpressCheckoutPayment_params
	# https://developer.paypal.com/docs/classic/api/merchant/DoExpressCheckoutPayment_API_Operation_NVP/
	# https://gist.github.com/xcommerce-gists/3502241
			response = paypal_express_request.checkout!(
				params['token'],
				params['PayerID'],
				Paypal::Payment::Request.new(doExpressCheckoutPayment_params)
			)
			log 'DoExpressCheckoutPayment RESPONSE', response.instance_values
			# http://stackoverflow.com/a/18811305
			currentTime = DateTime.current
			invoice.paid_at = DateTime.current
			case invoice.tier_period_units
				when 'y'
					advanceUnits = :years
				when 'm'
					advanceUnits = :months
				when 'd'
					advanceUnits = :days
			end
			invoice.membership_till = DateTime.current.advance(advanceUnits => +invoice.tier_period)
			invoice.save
			log 'INVOICE UPDATED', invoice.attributes
			groupIds = invoice.granted_group_ids.split(',')
			groupIds.each do |groupId|
				groupId = groupId.to_i
				# http://stackoverflow.com/a/25274645
				groupUser = GroupUser.find_by(user_id: current_user.id, group_id: groupId)
				if groupUser.nil?
					group = Group.find_by(id: groupId)
					# 2015-07-11
					# Группа могла быть удалена
					if group
						groupUser = GroupUser.new
						groupUser.user = current_user
						groupUser.group = group
						groupUser.save
						log "GRANTED MEMBERSHIP in «#{group.name}»"
					end
				end
			end
			redirect_to "#{Discourse.base_url}/users/#{current_user.username}"
		end
		private
		def log(message, params={})
			prefix = ''
			if current_user
				prefix += "[#{current_user.username}] "
			end
			if @invoice and @invoice.id
				prefix += "[##{invoice.id}] "
			end
			Airbrake.notify(:error_message => prefix + message, :parameters => params)
		end
		def paypal_express_request
			prefix = sandbox? ? 'Sandbox_' : ''
			Paypal::Express::Request.new(
				:username => SiteSetting.send("«PayPal»_#{prefix}API_Username"),
				:password => SiteSetting.send("«PayPal»_#{prefix}API_Password"),
				:signature => SiteSetting.send("«PayPal»_#{prefix}Signature")
			)
		end
		def paypal_set_sandbox_mode_if_needed
			Paypal.sandbox= sandbox?
			log sandbox? ? 'SANDBOX MODE' : 'PRODUCTION MODE'
		end
		def sandbox?
			'sandbox' == SiteSetting.send('«PayPal»_Mode')
		end
	end
end

