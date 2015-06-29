import SiteSetting from 'admin/components/site-setting';
export default {name: 'df-paid-membership-admin', after: 'inject-objects', initialize: function() {
	SiteSetting.reopen({
		partialType: function() {
			var type = this.get('setting.type');
			return 'paid_membership_plans' === type ? type : this._super();
		}.property('setting.type')
	});
}};
