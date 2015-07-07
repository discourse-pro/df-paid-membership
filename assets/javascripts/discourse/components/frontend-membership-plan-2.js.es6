export default Ember.Component.extend({
	_didInsertElement: function() {
		const color = '#' + this.get('plan').get('color').background;
		this.$().css({'border-color': color});
	}.on('didInsertElement')
	,_init: function() {
		const plan = this.get('plan');
		const tiers = plan.priceTiers;
		if (tiers) {
			const getPeriodUnitsLabel = function(tier) {
				const period = parseInt(tier.period);
				return I18n.t('paid_membership.price_tier.period_units.' + tier.periodUnits + '.' + (
					(1 === period)
					? '1'
					: ('ru' !== I18n.currentLocale())
						? 'many'
					  	: (5 > period ? '2' : '5')
			  	));
			};
			tiers.forEach(function(tier) {
				tier.periodUnitsLabel = getPeriodUnitsLabel(tier);
			});
		}
		this.set('currency', Discourse.SiteSettings['«PayPal»_Payment_Currency']);
	}.on('init')
});
