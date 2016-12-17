# https://developer.paypal.com/webapps/developer/docs/classic/products/#recurring
# https://developer.paypal.com/webapps/developer/docs/classic/paypal-payments-pro/integration-guide/WPRecurringPayments/
# https://developer.paypal.com/webapps/developer/docs/classic/express-checkout/integration-guide/ECRecurringPayments/
module ::Df::PaidMembership class SuccessRecurringController < SuccessController
	protected
	# @override
	def confirm_payment
		raise unless 'ActiveProfile' === subscription_response.recurring.status
	end
	# @override
	def invoice
		return @invoice if defined? @invoice
=begin
http://stackoverflow.com/a/25274645
2016-12-18
@todo Этот код возвращает последний неоплаченный счёт данного покупателя.
В нормальных ситациях этот код работает корректно,
но вообще говоря этот код может оставлять лазейку для хакерских атак,
и лучше искать не последний неоплаченный счёт
а именно тот счёт, который был сформирован в текущем сеансе оплаты,
а для этого надо здесь искать счёт по некоему идентификатору.

При этом у хакера всё-таки нет возможности прямолинейно оплатить предыдущий свой неоплаченный счёт,
повторно перейдя по ссылке типа https://site.com/plans/success?token=EC-7HT7821720850644K,
потому что время начала подписки берётся из счёта,
а PayPal проверяет время начала подписки, и недопускает ситациию, когда оно в прошлом:
«Subscription start date should be greater than current date».

Однако получается, что мы вместо корректного диагностического сообщения типа
«Покупатель пытается повторно активировать прошлую подписку»
получаем совсем нерелевантное сообщение «Subscription start date should be greater than current date».
Вот это одна из причин, почему счёт надо искать по идентификатору,
а не тупо возвращать последний неоплаченный.
=end
		@invoice = Invoice.where(user_id: user.id,  paid_at: nil).last
	end
	# @override
	def invoiceId
		invoice.id
	end
	# @override
	def update_invoice
		super
		invoice.recurring_profile_id = subscription_response.recurring.identifier
	end
	private
	def subscription_request_params
		return @subscription_request_params if defined? @subscription_request_params
		@subscription_request_params = Paypal::Payment::Recurring.new(
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BNA01I0E9__idd4198f0a-9b54-4cb2-90e9-2c7b4fdd0324
			:billing => {
				# AMT
				:amount => invoice.price,
				# CURRENCYCODE
				:currency_code => invoice.currency,
				# BILLINGFREQUENCY
				:frequency => invoice.tier_period,
				# BILLINGPERIOD
				:period => invoice.paypal_billing_period,
				:trial => {
					:period => :Day,
					:frequency => trialPeriod,
					:total_cycles => 1,
					:amount => 0
				}
			},
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BN9L00JPN__id156e9ad4-5e4d-463a-98fa-b34e350a1886
			# DESC
			:description => invoice.description,
			# https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#id09BNA100BE6__id7bd11dfe-c599-4af2-aea0-cdea481bad4b
			# SUBSCRIBERNAME
			:name => user.name.empty? ? user.username : user.name,
			# PROFILEREFERENCE
			:reference => invoice.id,
=begin
PROFILESTARTDATE
Передаваемое здесь время должно быть формате UTC или GMT:
https://developer.paypal.com/docs/classic/api/merchant/CreateRecurringPaymentsProfile_API_Operation_NVP/#recurring-payments-profile-details-fields
«Must be a valid date, in UTC/GMT format; for example, 2013-08-24T05:38:48Z. No wildcards are allowed.»
Z на конце обозначает формат UTC: http://stackoverflow.com/a/9706777
Разница между UTC и GMT в том, что GMT не учитывает переход на летнее время: http://stackoverflow.com/a/2292550

Раньше здесь стояло выражение: «invoice.created_at», однако оно возвращает время так: «2016-12-17 21:34:17»,
то есть не совсем в том формате, в котором хочет PayPal.
Я думал, что именно поэтому у меня  ближе к полуночи у меня происходил сбой:
«Subscription start date should be greater than current date».
https://github.com/discourse-pro/df-paid-membership/issues/8
http://magento.stackexchange.com/questions/8067#comment11056_8067
2016-12-17 21:34:17

Поэтому я сделал в в принципе правильное изменение: .to_formatted_s(:iso8601):
http://apidock.com/rails/Time/to_formatted_s

Однако это проблему «Subscription start date should be greater than current date» не устранило,
хотя время подписки у меня заведомо предшествует времени ответа сервера, напримрер:
время подписки: 2016-12-17T22:49:42Z
время ответа сервера: 2016-12-17T22:53:31Z

Поэтому отныне я устранил проблему так, как это сделано здесь: https://github.com/mobalean/subscription_fu/pull/2
То есть тупо добавляю одни сутки к текущему времени

Интересно, что валидация PayPal «Subscription start date should be greater than current date»
не даёт возможности хакеру повторно использовать ту же самую подписку,
повторно перейдя по ссылке типа https://site.com/plans/success?token=EC-7HT7821720850644K
=end
			:start_date => (invoice.created_at + 1.day).to_formatted_s(:iso8601)
		)
	end
	def subscription_response
		return @subscription_response if defined? @subscription_response
		@subscription_response = begin
			log 'CreateRecurringPaymentsProfile REQUEST', subscription_request_params
			# https://github.com/nov/paypal-express/wiki/Recurring-Payment#create-recurring-profile
			result = paypal_express_request.subscribe!(token, subscription_request_params)
			log 'CreateRecurringPaymentsProfile RESPONSE', result
			result
		end
	end
end end