export default Ember.Controller.extend({
	fillStyle: function() {
		return Ember.String.htmlSafe('background-color: #' + this.get('model.color'));
	}.property('model.color')
	,title: function() {return this.get('model.title');}.property('model.title')
});
