module ::Df::PaidMembership class IndexController < BaseController
	def index
		render json: {plans: plans}
	end
	protected
	# @override
	def log?
		false
	end
end end

