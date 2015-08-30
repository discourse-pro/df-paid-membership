require_dependency 'application_controller'
module ::Df::PaidMembership
	class BaseController < ::ApplicationController
		skip_before_filter :authorize_mini_profiler,
			:check_xhr,
			:inject_preview_style,
			:preload_json,
			:redirect_to_login_if_required,
			:set_current_user_for_logs,
			:set_locale,
			:set_mobile_view,
			# http://stackoverflow.com/a/22715175
			# http://stackoverflow.com/a/4551418
			:verify_authenticity_token
		before_filter :paypal_init
		protected
		def currency
			SiteSetting.send '«Money»_Currency'
		end
		def invoiceIdForLogging
			nil
		end
		def log(message, params={})
			if log?
				Airbrake.notify(:error_message => log_prefix + message, :parameters => params)
			end
		end
		def log?
			true
		end
		def log_prefix
			result = ''
			if current_user
				result += "[#{current_user.username}] "
			end
			result
		end
		def paypal_express_request
			prefix = sandbox? ? 'Sandbox_' : ''
			Paypal::Express::Request.new(
				:username => SiteSetting.send("«PayPal»_#{prefix}API_Username"),
				:password => SiteSetting.send("«PayPal»_#{prefix}API_Password"),
				:signature => SiteSetting.send("«PayPal»_#{prefix}Signature")
			)
		end
		def paypal_init
			Paypal.sandbox= sandbox?
			log sandbox? ? 'SANDBOX MODE' : 'PRODUCTION MODE'
		end
		def plans
			return @plans if defined? @plans
			@plans = begin
				JSON.parse(SiteSetting.send '«Paid_Membership»_Plans')
			rescue JSON::ParserError => e
				[]
			end
		end
		def recurring?
			SiteSetting.send('«PayPal»_Recurring')
		end
		def sandbox?
			# defined? @sandbox ? @sandbox : @sandbox = 'sandbox' === SiteSetting.send('«PayPal»_Mode')
			'sandbox' === SiteSetting.send('«PayPal»_Mode')
		end
		private
	end
end

