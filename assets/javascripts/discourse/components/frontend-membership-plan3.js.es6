/**
 * 2016-12-10
 * Раньше название компонента было «frontend-membership-plan-3».
 * Однако с текущей версией Ember.js (2.4.6, а раньше, видимо, использовалась версия 1.x),
 * компоненты с именами, у которых окончание после дефиса является цифрой,
 * больше не работают правильно:
 * шаблон *.hbs по-прежнему работает, но вот класс *.js.es6 (данный файл)
 * больше не обрабатывается системой.
 * По этой причине изменил окончание, убрав дефис перед цифрой.
 */
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
				 * @link http://stackoverflow.com/a/3012987
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
		this.set('signUpButtonLabel', Discourse.SiteSettings['«Paid_Membership»_«Sign_Up»_Button_Label']);
	}.on('init')
	,actions: {
		buy() {
			if (Discourse.User.current()) {
				const $currentRow = this.$().closest('tr');
				const columnIndex = $currentRow.children('td').index(this.$());
				const $prevRow = $currentRow.prev();
				const $cellAbove = $prevRow.children('td').eq(columnIndex);
				var selected = $('input[type=radio]:checked', $cellAbove).val();
				// 2015-07-26
				// По невнимательности администратора
				// у плана могут отсутствовать цены.
				if (selected) {
					Discourse.ajax('/plans/buy', {data: {
						user: Discourse.User.current().id
						,plan: this.get('plan').id
						,tier: selected
					}}).then(function(result) {
						window.location.replace(result.redirect_uri);
					});
				}
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
	 * @link http://stackoverflow.com/a/15401016
	 */
	,loginController: Discourse.__container__.lookup('controller:login')
});
