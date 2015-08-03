# name: df-paid-membership
# about: You can automatically sell membership in particular user groups.
# version: 2.0.0
# authors: Dmitry Fedyuk
# url: https://discourse.pro/t/35
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
	::Df::PaidMembership::Engine.routes.draw do
		get '/' => 'index#index'
		get '/buy' => 'index#buy'
		get '/ipn' => 'index#ipn'
		get '/success' => 'index#success'
	end
	Discourse::Application.routes.append do
		mount ::Df::PaidMembership::Engine, at: '/plans'
	end
end
