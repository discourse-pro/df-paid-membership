/**
 * 2016-12-09
 * Раньше здесь стояло Ember.ArrayController.extend
 * Однако сегодня заметил, что такой синтаксис уже не работает со свежей версией ядра,
 * и в самом ядре изменение Ember.ArrayController.extend на Ember.Controller.extend
 * произошло 2016-10-21 в коммите https://github.com/discourse/discourse/commit/bf9153
 * https://github.com/discourse/discourse/compare/2a61cc...bf9153
 *
 * Документация Ember.js: http://emberjs.com/deprecations/v1.x/#toc_arraycontroller
 * «Just like Ember.ObjectController, Ember.ArrayController will be removed in Ember 2.0
 * for the same reasons mentioned in 1.11's ObjectController deprecation.»
 */
export default Ember.Controller.extend({
	_init: function() {this.set('filterMode', 'paid_membership');}.on('init')
	,navItems: function() {
		return Discourse.NavItem.buildList(null, {filterMode: this.get('filterMode')});
	}.property('filterMode')
});