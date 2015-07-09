# name: df-paid-membership
# about: You can automatically sell membership in particular user groups.
# version: 1.0.0
# authors: Dmitry Fedyuk
# url: https://discourse.pro/t/35
gem 'attr_required', '1.0.0'
gem 'paypal-express', '0.8.1', {require_name: 'paypal'}
require 'json'
register_asset 'stylesheets/main.scss'
after_initialize do
	module ::PaidMembership
		class Engine < ::Rails::Engine
			engine_name 'df_paid_membership'
			isolate_namespace PaidMembership
		end
	end
	require_dependency 'application_controller'
	class PaidMembership::PlansController < ::ApplicationController
		#skip_before_filter :check_xhr
		def index
			begin
				plans = JSON.parse(SiteSetting.send '«Paid_Membership»_Plans')
			rescue JSON::ParserError => e
				plans = []
			end
			render json: { plans: plans }
		end
		def buy
			plans = JSON.parse(SiteSetting.send '«Paid_Membership»_Plans')
			plan = nil
			planId = params['plan']
			plans.each { |p|
				if planId == p['id']
					plan = p
					break
				end
			}
			tier = nil
			tierId = params['tier']
			plan['priceTiers'].each { |t|
				if tierId == t['id']
					tier = t
					break
				end
			}
			price = tier['price']
			currency = SiteSetting.send '«PayPal»_Payment_Currency'
			puts params['user']
			puts price
			puts currency
			render json: { test: ['тест'] }
		end
	end
	PaidMembership::Engine.routes.draw do
		get '/' => 'plans#index'
		get '/buy' => 'plans#buy'
	end
	Discourse::Application.routes.append do
		mount ::PaidMembership::Engine, at: '/plans'
	end
end
