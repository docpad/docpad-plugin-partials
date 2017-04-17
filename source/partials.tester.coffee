# Export Plugin Tester
module.exports = (testers) ->
	# Define Plugin Tester
	class MyTester extends testers.RendererTester
		# Configuration
		docpadConfig:
			logLevel: 5
			enabledPlugins:
				'partials': true
				'eco': true