export default Ember.Controller.extend({
	fillColor: '#ff0000'
	,fillStyle: function() {
		return Ember.String.htmlSafe('background-color:' + this.get('fillColor'));
	}.property('fillColor')
});
