export default function() {
	/**
	 * 2016-12-09
	 * Fix `this.resource` deprecation: https://github.com/discourse/discourse-tagging/commit/84a99df
	 *
	 * «resetNamespace: true» здесь не нужно, потому что «plans» и так является корневым путём:
	 * https://guides.emberjs.com/v2.0.0/routing/defining-your-routes/#toc_resetting-nested-route-namespace
	 */
	this.route('plans', function() {
		/**
		 * 2016-12-09
		 * Хотя в документации Ember.js сказано, что route «index» объявляется автоматически,
		 * у меня без него шаблон plans/index.hbs не отображается.
		 * https://guides.emberjs.com/v2.4.0/routing/defining-your-routes/#toc_index-routes
		 *
		 * 2016-12-10
		 * Сегодня заметил, что эта же проблема 10 дней назад возникла и в ядре,
		 * и там она была решена тем же способом:
		 * https://github.com/discourse/discourse/commit/a97c59ed2
		 */
    	this.route('index', {path: '/'});
 	});
}