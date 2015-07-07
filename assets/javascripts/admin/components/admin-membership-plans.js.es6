const createColor = function(color) {
	return {
		background: color
		,boxShadowX: arguments[1] || color
		,boxShadowY: arguments[2] || color
		,textShadow: arguments[3] || color
		,hoverBackground: arguments[4] || color
		,hoverBoxShadowX: arguments[5] || arguments[1] || color
		,hoverBoxShadowY: arguments[6] || arguments[2] || color
		,hoverTextShadow: arguments[7] || arguments[3] || color
	};
};
export default Ember.Component.extend({
	classNames: ['membership-plans']
	/**
	 * 2015-06-29
	 * Discourse expects the components's template at
	 * plugins/df-paid-membership/assets/javascripts/discourse/templates/components/admin-membership-plans.hbs
	 * Until I know it I used to specify template location explicitly:
	 * @link http://stackoverflow.com/a/24271614/254475
	 * ,layoutName: 'javascripts/admin/templates/components/admin-membership-plans'
	 * Now I save the explicit method for history only. May be it will be useful sometimes.
	 */
	,palette: [
		createColor('00aeef', '3dcaff', '0076a3', '009bd6')
		, createColor('f9a41a', 'e9b35c', 'ae7212', 'ae7212', 'c98414', null, '9c6610')
		, createColor('1bb058', '5fc78a', '127b3d', '127b3d', '158c46', '55b37c', '106e36', '106e36')
		, createColor('d13138')
		, createColor('283890')
	]
	,_changed: function() {
		if (this.get('initialized')) {
			Ember.run.once(this, function() {
				this.set('valueS', JSON.stringify(this.get('items')));
			});
		}
	}.observes(
		'items.@each'
		, 'items.@each.color'
		, 'items.@each.description'
		, 'items.@each.id'
		, 'items.@each.restrictionType'
		, 'items.@each.title'
		/**
		 * 2015-06-29
		 * Наблюдение за items.@each.allowedGroupIds и items.@each.allowedGroupIds не работает,
		 * потому что наблюдение, похоже, работает не более чем на два уровня вложенности:
		 * @link https://github.com/emberjs/ember.js/issues/541#issue-3401973
		 * Поэтому мы вызываем _changed() вручную из groupChanged().
		 */
	)
	,_didInsertElement: function() {
		// 2015-07-07
		// Стандартное для Ember.js наблюдение работает лишь на 2 уровня вложенности,
		// поэтому за изменениями палитры мы наблюдаем вручную.
		const _this = this;
		this.$('.hex-input').change(function() {_this._changed()});
	}.on('didInsertElement')
	,_init: function() {
		/** @type {String} */
		const valueS = this.get('valueS');
		/** @type {Object[]} */
		var items;
		try {
			/** @link http://caniuse.com/#feat=json */
			items = JSON.parse(valueS);
		}
		catch(ignore) {
			items = [];
		}
		// 2015-06-30
		// Для поддержки предыдущих версий, которые имели другую структуру данных.
		items.forEach(function(item) {
			if (!item.color) {
				item.color = createColor('f9a41a');
			}
			/** @link http://stackoverflow.com/a/8511350/254475 */
			else if ('object' !== typeof item.color) {
				item.color = createColor(item.color)
			}
		});
		this.set('items', items);
		this.set('restrictionTypeOptions', [
			{value: 'whitelist', label: I18n.t('paid_membership.plan.restriction_type.whitelist')}
			,{value: 'blacklist', label: I18n.t('paid_membership.plan.restriction_type.blacklist')}
		]);
		this.newItem();
		this.set('initialized', true);
	}.on('init')
	,newItem: function() {
		this.set('newId', this.generateNewId());
		this.set('allowedGroupIds', []);
		this.set('color', this.palette[Math.floor(this.palette.length * Math.random())]);
		this.set('description', I18n.t('paid_membership.plan.description_placeholder'));
		this.set('grantedGroupIds', []);
		this.set('priceTiers', []);
		this.set('restrictionType', 'whitelist');
		this.set('title', I18n.t('paid_membership.plan.title_placeholder'));
	}
	,generateNewId: function() {
		var items = this.get('items');
		var existingIds = $.map(items, function(item) {
			var matches = item.id.match(/^bbcode-plan-(\d+)/);
			return !matches || (2 > matches.length) ? 0 : parseInt(matches[1]);
		});
		/** @link http://stackoverflow.com/a/6102340/254475 */
		var max = !existingIds.length ? 0 : Math.max.apply(Math, existingIds);
		return 'bbcode-plan-' + (max + 1);
	}
	,actions: {
		addItem() {
			if (!this.get('inputInvalid')) {
				var items = this.get('items');
				var id = this.get('newId') || this.generateNewId();
				items.addObject({
					allowedGroupIds: this.get('allowedGroupIds')
					, color: this.get('color')
					/*createColor(
						this.get('color.background')
						,this.get('color.boxShadowX')
						,this.get('color.boxShadowY')
						,this.get('color.textShadow')
						,this.get('color.hoverBackground')
						,this.get('color.hoverBoxShadowX')
						,this.get('color.hoverBoxShadowY')
						,this.get('color.hoverTextShadow')
					) */
					, description: this.get('description')
					, grantedGroupIds: this.get('grantedGroupIds')
					, id: id
					, priceTiers: this.get('priceTiers')
					, restrictionType: this.get('restrictionType')
					, title: this.get('title')
				});
				this.newItem();
			}
		}
		,groupChanged(context) {
			const addGroup = function(groupIds) {
				groupIds.push(context.groupId);
			};
			const removeGroup = function(groupIds) {
				var indexToRemove = groupIds.indexOf(context.groupId);
				if (indexToRemove > -1) {
					groupIds.splice(indexToRemove, 1);
				}
			};
			var item = context.item;
			/**
			 * У нас 2 типа: «allowed» и «granted».
			 * @type {string}
			 */
			var groupPropertyName = context.type + 'GroupIds';
			// Если item не указан — значит, операция относится к новому элементу.
			var groupIds =
				item
				// 2015-06-30
				// Такое сложное выражение — для совместимости с прежними версиями,
				// когда свойства grantedGroupIds не существовало.
				? (item[groupPropertyName] || (item[groupPropertyName] = []))
				: this.get(groupPropertyName)
			;
			(context.isAdded ? addGroup : removeGroup).call(this, groupIds);
			/** @link https://github.com/emberjs/ember.js/issues/541#issue-3401973 */
			if (item) {
				this._changed();
			}
		}
		,priceTiersChanged(context) {
			if (context.plan) {
				this._changed();
			}
		}
		,removeItem(item) {this.get('items').removeObject(item);}
	}
	,inputInvalid: false//Ember.computed.empty('allowedGroupIds')
});
