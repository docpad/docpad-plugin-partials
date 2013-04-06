# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	eachr = require('eachr')
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

		# Partial helpers
		foundPartials: null  # Object
		partialsCache: null  # Object


		# -----------------------------
		# Initialize

		# Prepare our Configuration
		constructor: ->
			# Prepare
			super

			# Creatte our found partials object
			@partialsCache = {}
			@foundPartials = {}

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

		# -----------------------------
		# Rendering

		# Render Partial
		# Render a partial asynchronously
		# next(err,result,document)
		renderPartial: (partial,next) ->
			# Prepare
			docpad = @docpad
			locale = @locale
			partialsCache = @partialsCache
			result = null

			# Check if our partial is cacheable
			cacheable = partial.document.getMeta().get('cacheable') ? false
			if cacheable is true
				result = partialsCache[partial.path] ? null

			# Got from cache, so use that
			return next(null,result)  if result?

			# Render
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

		# Extend Template Data
		# Inject our partial methods
		extendTemplateData: ({templateData}) ->
			# Prepare
			me = @
			{docpad,locale,config} = @

			# Apply
			templateData.partial = (partialName,objs...) ->
				# Reference others
				@referencesOthers?()

				# Prepare
				file = @documentModel
				partial = {}

				# Fetch our partial
				partialFuzzyPath = pathUtil.join(config.partialsPath, partialName)
				partial.document ?= docpad.getCollection('partials').fuzzyFindOne(partialFuzzyPath)
				unless partial.document
					# Partial was not found
					message = util.format(locale.partialNotFound, partialName)
					err = new Error(message)
					partial.err = err
					return message

				# Fetch our partial data
				partial.data =
					if objs.length >= 2
						objs.unshift({})
						extendr.shallowExtendPlainObjects(objs...)
					else
						objs[0] ? {}

				# Prepare our partial id
				partial.id = Math.random() # require('crypto').createHash('md5').update(partial.document.id+'|'+JSON.stringify(partial.data)).digest('hex')
				partial.container = '[partial:'+partial.id+']'

				# Check if a partial with this id already exists!
				if me.foundPartials[partial.id]
					return partial.container

				# Store the partial
				me.foundPartials[partial.id] = partial

				# Return the container
				return partial.container

			# Chain
			@

		# Render the Document
		# Render our partials
		renderDocument: (opts,next) ->
			# Prepare
			{templateData,file} = opts

			# Prepare
			me = @
			partialsToRender = []

			# Find the partials
			opts.content = opts.content.replace /\[partial:([^\]]+)\]/g, (match,p1) ->
				partial = me.foundPartials[p1]
				return partial.result  if partial.result
				partialsToRender.push(partial)
				return match

			# Check
			return next()  if partialsToRender.length is 0

			# Otherwise render
			partialsRunner = new TaskGroup().setConfig(concurrency:0).once('complete',next)

			# Add the rendering tasks
			partialsToRender.forEach (partial) ->
				partialsRunner.addTask (complete) ->
					# Render partial
					me.renderPartial partial, (err,result) ->
						# Store result
						partial.err = err
						partial.result = result ? err.toString()

						# Replace
						opts.content = opts.content.replace(partial.container, partial.result)

						# Complete
						complete()

			# Execute the rendeirng taks
			partialsRunner.run()

			# Chain
			@

		# Generate After
		# Reset the found partials after each generate, otherwise it will get very big
		generateAfter: ->
			@foundPartials = {}
			@partialsCache = {}
