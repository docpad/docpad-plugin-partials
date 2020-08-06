'use strict'

// Test our plugin using DocPad's Testers
module.exports = require('docpad-plugintester').test(
	{},
	{
		logLevel: 5,
		enabledPlugins: {
			partials: true,
			eco: true,
		},
		plugins: {
			partials: {
				partialsPath: ['partials', 'custom-dir-partials'],
			},
		},
	}
)
