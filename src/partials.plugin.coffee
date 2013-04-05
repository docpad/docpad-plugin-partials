# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	extendr = require('extendr')
	{TaskGroup} = require('taskgroup')
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
		foundPartials: null  # Array

		# For cacheable partials, cache them here
		partialsCache: null  # Object


		# -----------------------------
		# Initialize

		# Prepare our Configuration
		constructor: ->
			# Prepare
			super

			# Creatte our found partials object
			@foundPartials = []
			@partialsCache = {}

			# DocPad -v6.24.0 Compatible
			@config.partialsPath = pathUtil.resolve(@docpad.getConfig().srcPath, @config.partialsPath)


		# DocPad v6.24.0+ Compatible
		# Configuration
		setConfig: ->
			# Prepare
			super

			# Adjust
			@config.partialsPath = pathUtil.resolve(@docpad.getConfig().srcPath, @config.partialsPath)

			# Chain
			@


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
			@foundPartials.push(partial)

			# Return the partial's container
			return partial.container


		# Render Partial
		# Render a partial asynchronously
		# next(err,result,document)
		renderPartial: (partial,next) ->
			# Prepare
			docpad = @docpad
			locale = @locale
			partialsCache = @partialsCache
			result = null

			# Check the partial exists
			partial.document ?= docpad.getCollection('partials').fuzzyFindOne(partial.path)

			# If it doesn't, warn
			unless partial.document
				message = util.format(locale.partialNotFound, partial.name)
				err = new Error(message)
				return next(err)  if err

			# Check if our partial is cacheable
			cacheable = partial.document.getMeta().get('cacheable') ? false
			if cacheable is true
				result = partialsCache[partial.path] ? null

			# Got from cache, so use that
			if result?
				return next(null,result)

			# Render
			else
				docpad.renderDocument partial.document, {templateData:partial.data}, (err,result,document) ->
					# Check
					return next(err)  if err

					# Cache
					if cacheable is true
						partialsCache[partial.path] = result

					# Forward
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
					data = extendr.shallowExtendPlainObjects(objs...)
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
			tasks = new TaskGroup().setConfig(concurrency:0).on('complete',next)

			# Store all our files to be cached
			foundPartials.forEach (partial) ->
				tasks.addTask (complete) ->
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
			tasks.run()

			# Chain
			@

		# Generate After
		# Reset the found partials after each generate, otherwise it will get very big
		generateAfter: ->
			@foundPartials = []
			@partialsCache = {}
