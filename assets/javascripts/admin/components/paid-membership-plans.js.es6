export default Ember.Component.extend({
	classNameBindings: [':paid-membership-plans']
	/** @link http://stackoverflow.com/a/24271614/254475 */
	,layoutName: 'javascripts/admin/templates/components/paid-membership-plans'
	,_serialize: function() {this.set('valueS', JSON.stringify(this.get('items')));}
	,onInit: function() {
		this.set('selectedUserGroups', []);
		const _this = this;
		Discourse.Group.findAll().then(function(availableUserGroups){
			console.log(availableUserGroups);
			_this.set('availableUserGroups', availableUserGroups);
		});
		/** @type {String} */
		const valueS = this.get('valueS');
		/** @type {Object[]} */
		var items;
		try {
			/** @link http://caniuse.com/#feat=json */
			items = JSON.parse(valueS);
		}
		catch(ignore) {
			// Legacy support.
			/** @type {String[]} */
			var htmlA = valueS && valueS.length ? valueS.split("\n") : [];
			items = [];
			htmlA.forEach(function(html, index) {
				items.push({id: 'membership-plan-' + (1 + index), html: html});
			});
		}
		this.set('items', items);
		this.initNewButton();
		this.set('initialized', true);
	}.on('init')//.observes('valueS')
	,_changed: function() {
		if (this.get('initialized')) {
			Ember.run.once(this, '_serialize');
		}
	}.observes('items.@each', 'items.@each.id', 'items.@each.html')
	,initNewButton: function() {
		this.set('newId', this.generateNewId());
		this.set('newHtml', I18n.t('admin.site_settings.paid_membership.plan.placeholder'));
	}
	,generateNewId: function() {
		var items = this.get('items');
		var existingIds = $.map(items, function(item) {
			var matches = item.id.match(/^membership-plan-(\d+)/);
			return !matches || (2 > matches.length) ? 0 : parseInt(matches[1]);
		});
		/** @link http://stackoverflow.com/a/6102340/254475 */
		var max = !existingIds.length ? 0 : Math.max.apply(Math, existingIds);
		return 'membership-plan-' + (max + 1);
	}
	,actions: {
		addItem() {
			if (!this.get('inputInvalid')) {
				var items = this.get('items');
				var id = this.get('newId') || this.generateNewId();
				items.addObject({id: id, html: this.get('newHtml')});
				this.initNewButton();
			}
		}
		,removeItem(item) {
			const items = this.get('items');
			items.removeObject(item);
		}
	}
	,inputInvalid: Ember.computed.empty('newHtml')
});
