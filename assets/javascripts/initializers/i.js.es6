import NavItem from 'discourse/plugins/df-core/models/nav-item';
export default {name: 'df-paid-membership', initialize() {
	if (Discourse.SiteSettings['«Paid_Membership»_Enable']) {
		I18n.translations[I18n.locale].js.filters.paid_membership = {
			help: Discourse.SiteSettings['«Paid_Membership»_Menu_Item_Tooltip']
			,title: Discourse.SiteSettings['«Paid_Membership»_Menu_Item_Title']
		};
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