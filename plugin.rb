# name: df-paid-membership
# about: You can automatically sell membership in particular user groups.
# version: 1.0.0
# authors: Dmitry Fedyuk
# url: https://discourse.pro/t/35
register_asset 'stylesheets/main.scss'
after_initialize do
	module ::PaidMembership
		class Engine < ::Rails::Engine
			engine_name 'paid_membership'
			isolate_namespace PaidMembership
		end
	end
	require_dependency 'application_controller'
	class PaidMembership::IndexController < ::ApplicationController
		requires_plugin 'df-paid-membership'
		def index
			render json: {plans: ['test']}
		end
	end
	PaidMembership::Engine.routes.draw do
		get '/' => 'index#index'
	end
	Discourse::Application.routes.append do
		mount ::PaidMembership::Engine, at: '/membership'
	end
end
