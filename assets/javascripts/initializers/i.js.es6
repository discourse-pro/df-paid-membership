import NavItem from 'discourse/plugins/df-core/models/nav-item';
export default {name: 'df-paid-membership', initialize() {
	if (Discourse.SiteSettings['«Paid_Membership»_Enable']) {
		Discourse.NavItem.reopenClass({
			buildList : function(category, args) {
				var list = this._super(category, args);
				if (!category) {
					list.push(NavItem.create({href: '/plans', name: 'paid_membership'}));
				}
				return list;
			}
		});
	}
}};