# name: df-paid-membership
# about: You can automatically sell membership in particular user groups.
# version: 3.1.1
# authors: Dmitry Fedyuk
# url: https://discourse.pro/t/35
# https://github.com/nov/paypal-express/wiki
require 'paypal'
require 'airbrake'
require 'json'
register_asset 'stylesheets/main.scss'
pluginAppPath = "#{Rails.root}/plugins/df-paid-membership/app/"
Discourse::Application.config.autoload_paths += Dir["#{pluginAppPath}models", "#{pluginAppPath}controllers"]
after_initialize do
	module ::Df
		module PaidMembership
			class Engine < ::Rails::Engine
				engine_name 'df_paid_membership'
				isolate_namespace ::Df::PaidMembership
			end
		end
	end
	successSuffix = SiteSetting.send('«Paid_Membership»_Recurring') ? 'recurring' : 'simple'
	::Df::PaidMembership::Engine.routes.draw do
		get '/' => 'index#index'
		get '/buy' => 'buy#index'
		get '/ipn' => 'ipn#index'
		get '/success' => "success_#{successSuffix}#index"
	end
	Discourse::Application.routes.append do
		mount ::Df::PaidMembership::Engine, at: '/plans'
	end
end
