/**
 * 2015-06-30
 * Очень хорошая статья о назначении price tiers:
 * http://summitevergreen.com/why-tiered-pricing-is-the-only-way-to-price-your-product/
 */
/**
 * Возвращает случайный короткий (7-значный) идентификатор
 * (некое число в 16-ричной системе счисления, представленное в виде строки).
 * @link http://stackoverflow.com/a/105074/254475
 * @returns {string}
 */
const newId = function() {
  return Math.floor((1 + Math.random()) * 0x10000000)
    .toString(16)
    .substring(1);
};
export default Ember.Component.extend({
	classNames: ['membership-price-tiers']
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
		, 'items.@each.id'
		, 'items.@each.price'
		, 'items.@each.period'
		, 'items.@each.periodUnits'
	)
	,_init: function() {
		var periodUnitsOptions = [];
		['d', 'm', 'y'].forEach(function(unit) {
			periodUnitsOptions.push({
				value: unit
				, label: I18n.t('paid_membership.price_tier.period_units.' + unit + '.undefined')
			})
		});
		this.set('periodUnitsOptions', periodUnitsOptions);
		this.set('currency', Discourse.SiteSettings['«Money»_Currency']);
		/** @type {Object[]} */
		var items = this.get('items');
		// 2015-07-07
		// Для поддержки предыдущих версий, которые имели другую структуру данных.
		items.forEach(function(item) {
			if (!item.id) {
				item.id = newId();
			}
		});
		this.newItem();
		this.set('initialized', true);
	}.on('init')
	,newItem: function() {
		this.set('id', newId());
		this.set('price', 9);
		this.set('period', 1);
		this.set('periodUnits', 'm');
	}
	,actions: {
		addItem() {
			if (!this.get('inputInvalid')) {
				var items = this.get('items');
				items.addObject({
					id: newId()
					, price: this.get('price')
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
