# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	balUtil = require('bal-util')
	pathUtil = require('path')
	util = require('util')

	# Define Plugin
	class PartialsPlugin extends BasePlugin
		# Plugin Name
		name: 'partials'

		# Default Configuration
		config:
			partialsPath: 'partials'

		# Locale
		locale:
			addingPartial: "Adding partial: %s"
			partialNotFound: "The partial \"%s\" was not found, as such it will not be rendered."
			renderPartial: "Rendering partial: %s"
			renderedPartial: "Rendered partial: %s"
			renderPartialFailed: "Rendering partial failed: %s. The error follows:"

		# A list of all the partials we've discovered
		foundPartials: null  # Object

		# Prepare our Configuration
		constructor: ->
			# Prepare
			super
			docpad = @docpad
			config = @config

			# Resolve our partialsPath
			config.partialsPath = pathUtil.resolve(docpad.config.srcPath, config.partialsPath)

			# Create our found partials object
			@foundPartials = {}


		# -----------------------------
		# Helpers

		# Render Partial Sync
		# Mapped to templateData.partial
		# Takes in a partialId and it's data and returns a temporary container
		# which will be replaced later when we've finished rendering our partial
		renderPartialSync: (name,data) ->
			# Prepare
			config = @config

			# Prepare our partials entry
			id = Math.random()
			partial =
				id: id
				name: name
				data: data
				path: pathUtil.join(config.partialsPath, name)
				container: "[partial:#{id}]"

			# Store it for later
			@foundPartials[id] = partial

			# Return the partial's container
			return partial.container


		# Render Partial
		# Render a partial asynchronously
		# next(err,result,document)
		renderPartial: (partial,next) ->
			# Prepare
			docpad = @docpad
			locale = @locale

			# Check the partial exists
			partial.document ?= docpad.getCollection('partials').fuzzyFindOne(partial.path)

			# If it doesn't, warn
			unless partial.document
				message = util.format(locale.partialNotFound, partial.name)
				err = new Error(message)
				return next(err)  if err

			# Render
			docpad.renderDocument partial.document, {templateData:partial.data}, (err,result,document) ->
				return next(err)  if err
				return next(null,result)

			# Chain
			@


		# -----------------------------
		# Events

		# Populate Collections
		populateCollections: (opts,next) ->
			# Prepare
			config = @config
			docpad = @docpad

			# Load our partials directory
			docpad.parseDocumentDirectory({path:config.partialsPath}, next)

			# Chain
			@

		# Extend Collections
		extendCollections: (opts) ->
			# Prepare
			config = @config
			docpad = @docpad
			locale = @locale

			# Add our partials collection
			docpad.setCollection 'partials', docpad.database.createLiveChildCollection()
				.setQuery('isLayout', {
					$or:
						isPartial: true
						fullPath: $startsWith: config.partialsPath
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingPartial, model.attributes.fullPath))
					model.attributes.isPartial ?= true
					model.attributes.render ?= false
					model.attributes.write ?= false
				)

			# Chain
			@

		# Extend Template Data
		# Inject our partial methods
		extendTemplateData: ({templateData}) ->
			# Prepare
			me = @

			# Apply
			templateData.partial = (name,objs...) ->
				# Reference others
				@referencesOthers?()

				# Extend
				if objs.length >= 2
					objs.unshift({})
					data = balUtil.shallowExtendPlainObjects(objs...)
				else
					data = objs[0] ? {}

				# Render sync
				return me.renderPartialSync(name,data)

			# Chain
			@


		# Render the Document
		# Render our partials
		renderDocument: (opts,next) ->
			# Prepare
			{templateData,file} = opts

			# Prepare
			me = @
			docpad = @docpad
			locale = @locale
			config = @config
			foundPartials = @foundPartials

			# Async
			tasks = new balUtil.Group(next)

			# Store all our files to be cached
			balUtil.each foundPartials, (partial) ->
				tasks.push (complete) ->
					# Check if we use this partial
					# if we don't, then skip this partial
					if opts.content.indexOf(partial.container) is -1
						return complete()

					# Log
					docpad.log('debug', util.format(locale.renderPartial, partial.name))

					# Render
					me.renderPartial partial, (err,contentRendered) ->
						# Check
						if err
							# Warn
							message = util.format(locale.renderPartialFailed, partial.name)
							docpad.warn(message, err)

						# Replace container with the rendered content
						else
							# Log
							docpad.log('debug', util.format(locale.renderedPartial, partial.name))

							# Apply
							opts.content = opts.content.replace(partial.container,contentRendered)

						# Done
						return complete()

			# Fire the tasks together
			tasks.async()

			# Chain
			@

		# Generate After
		# Reset the found partials after each generate, otherwise it will get very big
		generateAfter: ->
			@foundPartials = {}
