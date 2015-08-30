module ::Df::PaidMembership class IpnController < BaseController
	def index
		no_cookies
		log 'IPN', params
		Paypal::IPN.verify!(request.raw_post)
		render :nothing => true
	end
end end