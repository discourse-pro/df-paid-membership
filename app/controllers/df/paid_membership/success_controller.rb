module ::Df::PaidMembership class SuccessController < BaseController
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
		log 'CUSTOMER RETURNED', params
		begin
			confirm_payment
			update_invoice
			invoice.save
			log 'INVOICE UPDATED', invoice
			grant_membership
			redirect_to "#{Discourse.base_url}/users/#{current_user.username}"
		rescue => e
			log e
			redirect_to "#{Discourse.base_url}/plans"
		end
	end
	protected
	# @abstract
	def confirm_payment
	end
	# @abstract
	def invoice
		nil
	end
	def token
		params['token']
	end
	def update_invoice
		# http://stackoverflow.com/a/18811305
		currentTime = DateTime.current
		invoice.paid_at = DateTime.current
		case invoice.tier_period_units
			when 'y'
				advanceUnits = :years
			when 'm'
				advanceUnits = :months
			when 'd'
				advanceUnits = :days
		end
		invoice.membership_till = DateTime.current.advance advanceUnits => +invoice.tier_period
	end
	private
	def grant_membership
		groupIds = invoice.granted_group_ids.split ','
		groupIds.each do |groupId|
			groupId = groupId.to_i
			# http://stackoverflow.com/a/25274645
			groupUser = GroupUser.find_by user_id: current_user.id, group_id: groupId
			if groupUser.nil?
				group = Group.find_by id: groupId
				# 2015-07-11
				# Группа могла быть удалена
				if group
					groupUser = GroupUser.new
					groupUser.user = current_user
					groupUser.group = group
					groupUser.save
					log "GRANTED MEMBERSHIP in «#{group.name}»"
				end
			end
		end
	end
end end