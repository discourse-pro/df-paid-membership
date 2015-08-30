module ::Df::PaidMembership class IpnController < BaseController
	skip_before_filter :authorize_mini_profiler,
		:check_xhr,
		:inject_preview_style,
		:preload_json,
		:redirect_to_login_if_required,
		:set_current_user_for_logs,
		:set_locale,
		:set_mobile_view,
		:verify_authenticity_token
	def index
		no_cookies
		log 'IPN', params
		Paypal::IPN.verify!(request.raw_post)
		render :nothing => true
	end
end end