import { cook } from 'discourse/lib/text';
export default Ember.Controller.extend({
	textAbove: cook(Discourse.SiteSettings['«Paid_Membership»_Text_Above'])
});
