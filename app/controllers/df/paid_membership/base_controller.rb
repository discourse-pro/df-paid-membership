require_dependency 'application_controller'
module ::Df::PaidMembership class BaseController < ::ApplicationController
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
			# 2015-08-31
			# http://stackoverflow.com/a/15769829
			# http://stackoverflow.com/a/5367123
			# http://stackoverflow.com/questions/5030553#comment19063898_13204582
			# attributes присутствует только у ActiveRecord
			if params.respond_to? :attributes
				params = params.attributes
			# http://stackoverflow.com/a/5030763
			elsif params.respond_to? :instance_variables
				hash = {}
				params.instance_variables.each {|var|
					hash[var.to_s.delete("@")] = params.instance_variable_get(var)
				}
				params = hash
			end
			Airbrake.notify(:error_message => log_prefix + message, :parameters => params)
		end
	end
	def log?
		true
	end
	# 2015-08-30
	# Не кэшируем результат, потому что invoice может сначала не существовать,
	# а потом существовать.
	def log_prefix
		result = ''
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
	def recurring?
		SiteSetting.send '«Paid_Membership»_Recurring'
	end
	def user
		current_user
	end
	private
	def paypal_init
		Paypal.sandbox= sandbox?
		log sandbox? ? 'SANDBOX MODE' : 'PRODUCTION MODE'
	end
	def sandbox?
		# defined? @sandbox ? @sandbox : @sandbox = 'sandbox' === SiteSetting.send('«PayPal»_Mode')
		'sandbox' === SiteSetting.send('«PayPal»_Mode')
	end
end end

