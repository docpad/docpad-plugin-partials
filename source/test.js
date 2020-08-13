'use strict'

// Test our plugin using DocPad's Testers
module.exports = require('docpad-plugintester').test(
	{},
	{
		plugins: {
			partials: {
				partialsPath: ['partials', 'custom-dir-partials'],
			},
		},
	}
)
