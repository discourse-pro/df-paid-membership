export default Ember.Component.extend({
	_didInsertElement: function() {
		const color = '#' + this.get('plan').get('color').background;
		this.$().css({'border-color': color});
	}.on('didInsertElement')
	,_init: function() {
		this.set('currency', Discourse.SiteSettings['«PayPal»_Payment_Currency']);
	}.on('init')
});
