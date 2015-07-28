export default Ember.ArrayController.extend({
	textAbove: Discourse.Markdown.cook(Discourse.SiteSettings['«Paid_Membership»_Text_Above'])
});
