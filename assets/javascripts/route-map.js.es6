export default function() {
	// 2016-12-09
	// Fix `this.resource` deprecation
	// https://github.com/discourse/discourse-tagging/commit/84a99df
	this.route('plans', {path: '/plans', resetNamespace: true}, function() {});
}