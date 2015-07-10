export default Ember.Component.extend({
	_didInsertElement: function() {
		const c = function(color) {return '#' + color;};
		// Вызывается после вызова всех init для всех компонентов.
		const color = this.get('plan').get('color');
		this.$().css({'border-color': c(color.background)});
		const $button = this.$('.sign-up');
		const css = function(background, boxShadowX, boxShadowY, textShadow) {
			return {
				'background-color': c(color[background])
				/**
				 * 2015-07-07
				 * К сожалению, невозможно задать только цвет для box-shadow
				 * (не задавая остальные параметры):
				 * @link http://stackoverflow.com/a/3012987/254475
				 */
				,'box-shadow':
					'inset 0 1px ' + c(color[boxShadowX])
					+ ', 0px 5px ' + c(color[boxShadowY])
					+ ', 0 3px 5px rgba(0,0,0,.3)'
				,'text-shadow': '-1px 1px ' + c(color[textShadow])
			};
		};
		const cssDefault = css('background', 'boxShadowX', 'boxShadowY', 'textShadow');
		const cssHover = css('hoverBackground', 'hoverBoxShadowX', 'hoverBoxShadowY', 'hoverTextShadow');
		$button.css(cssDefault);
		$button.hover(
			function() {$button.css(cssHover);}
			,function() {$button.css(cssDefault);}
		);
	}.on('didInsertElement')
	,_init: function() {
		this.set('notLoggedIn', !Discourse.User.current());
	}.on('init')
	,actions: {
		buy() {
			if (Discourse.User.current()) {
				const $currentRow = this.$().closest('tr');
				const columnIndex = $currentRow.children('td').index(this.$());
				const $prevRow = $currentRow.prev();
				const $cellAbove = $prevRow.children('td').eq(columnIndex);
				var selected = $('input[type=radio]:checked', $cellAbove).val();
				Discourse.ajax('/plans/buy', {data: {
					user: Discourse.User.current().id
					,plan: this.get('plan').id
					,tier: selected
				}}).then(function(result) {
					window.location.replace(result.redirect_uri);
				});
			}
		}
		,login() {
			this.loginController.session.set('shouldRedirectToUrl', window.location.href);
			this.loginController.send('showLogin');
		}
		,register() {this.loginController.send('createAccount');}
	}
	/**
	 * @see app/assets/javascripts/discourse.js
	 * @link http://stackoverflow.com/a/15401016/254475
	 */
	,loginController: Discourse.__container__.lookup('controller:login')
});
