export default Ember.ArrayController.extend({
	_init: function() {
		//console.log('ArrayController init');
	}.on('init')
	, textAbove: Discourse.Markdown.cook(Discourse.SiteSettings['«Paid_Membership»_Text_Above'])
});
