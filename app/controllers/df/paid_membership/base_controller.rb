require_dependency 'application_controller'
module ::Df::PaidMembership class BaseController < ::ApplicationController
	# 2016-12-20
	# https://docs.sentry.io/clients/ruby/integrations/rails/#params-and-sessions
	before_action :set_raven_context
	before_filter :paypal_init
	protected
	def currency
		SiteSetting.send '«Money»_Currency'
	end
	def invoiceId
		nil
	end
	def log(message, params={})
		if log?
			if message.is_a?(Exception)
				# 2016-12-20
				# https://docs.sentry.io/clients/ruby/#reporting-failures
				Raven.capture_exception(message)
			else
				# 2016-12-20
				# https://docs.sentry.io/clients/ruby/context/
				Raven.capture_message message,
					extra: params.as_json,
					# 2016-12-25
					# Чтобы события разных магазинов не группировались вместе.
					# https://docs.sentry.io/learn/rollups/#customize-grouping-with-fingerprints
					fingerprint: ["{{ default }}", Discourse.current_hostname],
=begin
2016-12-23
«The record severity. Defaults to error.»
https://docs.sentry.io/clientdev/attributes/#optional-attributes
При использовании значения «debug»
у сообщения в списке сообщений в интерфейсе Sentry не будет никакой метки.
При использовании значения «info»
у сообщения в списке сообщений в интерфейсе Sentry будет синяя метка «Info».
https://docs.sentry.io/clients/ruby/context/
=end
					level: 'debug',
					server_name: Discourse.current_hostname
			end
		end
	end
	def log?
		true
	end
	# 2015-08-30
	# Не кэшируем результат, потому что invoice может сначала не существовать,
	# а потом существовать.
	def log_prefix
		# 2016-12-19
		result = "[#{Discourse.current_hostname}]"
		if user
			result += "[#{user.username}] "
		end
		if invoiceId
			result += "[##{invoiceId}] "
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
	def plans
		return @plans if defined? @plans
		@plans = begin
			JSON.parse(SiteSetting.send '«Paid_Membership»_Plans')
		rescue JSON::ParserError => e
			[]
		end
	end
	def user
		current_user
	end
	private
	def paypal_init
		Paypal.sandbox= sandbox?
	end
	def sandbox?
		'sandbox' === SiteSetting.send('«PayPal»_Mode')
	end
	# 2016-12-20
	# https://docs.sentry.io/clients/ruby/integrations/rails/#params-and-sessions
	def set_raven_context
		Raven.extra_context(
			params: params.to_unsafe_h,
			'PayPal Mode' => sandbox? ? 'sandbox' : 'production',
			url: request.url
		)
		# 2016-12-20
		# https://docs.sentry.io/clients/ruby/context/#tags
		Raven.tags_context(
			'Domain' => Discourse.current_hostname,
			'PayPal Mode' => sandbox? ? 'sandbox' : 'production'
		)
		# 2016-12-20
		# https://docs.sentry.io/clients/ruby/context/#user-context
		# https://docs.sentry.io/clientdev/interfaces/user/
		Raven.user_context({ip_address: request.ip}.merge(
			!user \
			? {id: session[:session_id]}
			: {
				email: user.email,
				id: user.id,
				name: user.name ? user.name : nil,
				username: user.username
			}
		))
	end
	# 2016-12-12
	# @return [Integer]
	def trialPeriod
		SiteSetting.send('«Paid_Membership»_Trial_Period').to_i
	end
end end

