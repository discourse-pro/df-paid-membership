# name: df-paid-membership
# about: You can automatically sell membership in particular user groups.
# version: 1.0.0
# authors: Dmitry Fedyuk
# url: https://discourse.pro/t/35
register_asset 'stylesheets/main.scss'
after_initialize do
	module ::DfPaidMembership
		class Engine < ::Rails::Engine
			engine_name 'df_paid_membership'
			isolate_namespace DfPaidMembership
		end
	end
	require_dependency 'application_controller'
	class DfPaidMembership::PlansController < ::ApplicationController
		def index
			render json: { success: 'OK' }
		end
	end
	DfPaidMembership::Engine.routes.draw do
		get '/' => 'plans#index'
	end
	Discourse::Application.routes.append do
		mount ::DfPaidMembership::Engine, at: '/plans'
	end
end
