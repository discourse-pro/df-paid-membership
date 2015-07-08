export default Ember.Component.extend({
	classNames: ['options']
	,_didInsertElement: function() {
		const color = '#' + this.get('plan').get('color').background;
		this.$().css({'border-color': color});
		const $currentRow = this.$().closest('tr');
		const columnIndex = $currentRow.children('td').index(this.$());
		const $nextRow = $currentRow.next();
		const $cellBelow = $nextRow.children('td').eq(columnIndex);
		const buttonWidth = $('a.sign-up', $cellBelow).outerWidth();
		this.$('.options-outer').width(buttonWidth);
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
			// 2015-07-08
			// По-умолчанию выбираем последнюю (подразумевается, что самую дорогую) опцию.
			this.set('selection', tiers[tiers.length - 1].id);
		}
		this.set('currency', Discourse.SiteSettings['«PayPal»_Payment_Currency']);
		this.set('notLoggedIn', !Discourse.User.current());
		this.set('optionName', 'plan_' + plan.id + '_price_tier');
	}.on('init')
});
