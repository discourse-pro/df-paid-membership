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
	class PaidMembership::IndexController < ::ApplicationController
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
			user = User.find_by(id: params['user'])
			Paypal.sandbox!
			paypal_options = {
				no_shipping: true, # if you want to disable shipping information
				allow_note: false, # if you want to disable notes
				pay_on_paypal: true # if you don't plan on showing your own confirmation step
			}
			request = Paypal::Express::Request.new(
				:username   => SiteSetting.send('«PayPal»_Sandbox_API_Username'),
				:password   => SiteSetting.send('«PayPal»_Sandbox_API_Password'),
				:signature  => SiteSetting.send('«PayPal»_Sandbox_Signature')
			)
			description =
				"Membership Plan ""#{plan['title']}""." +
				" User: #{user.username}." +
				" Period: #{tier['period']} #{tier['periodUnits']}."
			puts description
			payment_request = Paypal::Payment::Request.new(
				:currency_code => currency,
				:description => description,
				:quantity => 1,
				:amount => price,
				:notify_url => 'https://discourse.pro/plans/notify',
				:custom_fields => {
					#CARTBORDERCOLOR: "C00000",
					#LOGOIMG: "https://example.com/logo.png"
				}
			)
			response = request.setup(
				payment_request,
				'https://discourse.pro/plans',
				'https://discourse.pro/plans',
				paypal_options
			)
			puts response.redirect_uri
			render json: { redirect_uri: response.redirect_uri }
		end
	end
	PaidMembership::Engine.routes.draw do
		get '/' => 'index#index'
		get '/buy' => 'index#buy'
	end
	Discourse::Application.routes.append do
		mount ::PaidMembership::Engine, at: '/plans'
	end
end
