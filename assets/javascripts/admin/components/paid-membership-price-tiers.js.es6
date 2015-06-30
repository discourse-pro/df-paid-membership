/**
 * 2015-06-30
 * Очень хорошая статья о назначении price tiers:
 * http://summitevergreen.com/why-tiered-pricing-is-the-only-way-to-price-your-product/
 */
export default Ember.Component.extend({
	classNameBindings: [':paid-membership-price-tiers']
	,onInit: function() {
		this.newItem();
		this.set('initialized', true);
	}.on('init')
	,_changed: function() {
		if (this.get('initialized')) {
			Ember.run.once(this, function() {
				this.triggerAction({action:'priceTiersChanged', actionContext: {
					plan: this.get('plan')
				}});
			});
		}
	}.observes(
		'items.@each'
		, 'items.@each.price'
		, 'items.@each.period'
		, 'items.@each.periodUnits'
	)
	,newItem: function() {
		this.set('price', 0);
		this.set('period', 1);
		this.set('periodUnits', 'm');
	}
	,actions: {
		addItem() {
			if (!this.get('inputInvalid')) {
				var items = this.get('items');
				items.addObject({
					price: this.get('price')
					, period: this.get('period')
					, periodUnits: this.get('periodUnits')
				});
				this.newItem();
			}
		}
		,removeItem(item) {this.get('items').removeObject(item);}
	}
	,inputInvalid: false//Ember.computed.empty('allowedGroupIds')
});
