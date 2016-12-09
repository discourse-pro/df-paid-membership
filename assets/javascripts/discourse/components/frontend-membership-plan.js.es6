import {cook} from 'discourse/lib/text';
export default Ember.Component.extend({
	_didInsertElement: function() {
		// Вызывается после вызова всех init для всех компонентов.
		const color = '#' + this.get('plan').get('color').background;
		this.$().css({'border-color': color});
		this.$('.header').css({'background-color': color});
	}.on('didInsertElement')
	,_init: function() {
		const plan = this.get('plan');
		this.set('description', cook(plan.description));
	}.on('init')
});
