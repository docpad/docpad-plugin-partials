# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	extendr = require('extendr')
	{Task,TaskGroup} = require('taskgroup')
	pathUtil = require('path')
	util = require('util')

	# Define Plugin
	class PartialsPlugin extends BasePlugin
		# Plugin Name
		name: 'partials'

		# Default Configuration
		config:
			partialPaths: ['partials']
			collectionName: 'partials'
			performanceFirst: false

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
			@prepareConfig()
			# Creatte our found partials object
			@partialsCache = {}
			@foundPartials = {}


		# DocPad v6.24.0+ Compatible
		# Configuration
		setConfig: ->
			# Prepare
			super
			@prepareConfig()
		
			# Chain
			@
 
		# Prepare our Configuration
		prepareConfig: ->
			docpadConfig = @docpad.getConfig()
			config = @getConfig()
		
			# ensure config name backward compatibility
			config.partialPaths = config.partialsPath or config.partialPaths
		
			# ensure the partialPaths is an array
			unless util.isArray(config.partialPaths)
				config.partialPaths = [config.partialPaths]
		
			# Adjust
			config.partialPaths.forEach (partialPath, index) ->
				config.partialPaths[index] = pathUtil.resolve(docpadConfig.srcPath, partialPath)
				return
		
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
			processedCount = 0
			config.partialPaths.forEach (partialPath) ->
				docpad.parseDocumentDirectory {path: partialPath}, (err, results) ->
					if err or processedCount==(config.partialPaths.length-1)
						next(err)
		
					processedCount++
					return
				return

			# Chain
			@

		# Extend Collections
		extendCollections: (opts) ->
			# Prepare
			config = @getConfig()
			docpad = @docpad
			locale = @locale
			database = docpad.getDatabase()

			# Add our partials collection
			docpad.setCollection(config.collectionName, database.createLiveChildCollection()
				.setQuery('isPartial', {
					$or:
						isPartial: true
						fullPath: $startsWith: config.partialPaths[0]
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingPartial, model.getFilePath()))
					model.setDefaults(
						isPartial: true
						render: false
						write: false
					)
				)
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
				result = partialsCache[partial.cacheId] ? null

			# Got from cache, so use that
			return next(null, result)  if result?

			# Render
			docpad.renderDocument partial.document, {templateData:partial.data}, (err,result,document) ->
				# Check
				return next(err)  if err

				# Cache
				if cacheable is true
					partialsCache[partial.cacheId] = result

				# Forward
				return next(null, result)

			# Chain
			@

		# Extend Template Data
		# Inject our partial methods
		extendTemplateData: ({templateData}) ->
			# Prepare
			me = @
			docpad = @docpad
			locale = @locale

			# Apply
			templateData.partial = (partialName, objs...) ->
				# Reference others
				config = me.getConfig()
				@referencesOthers?()

				# Prepare
				file = @documentModel
				partial = {}

				# Fetch our partial
				#partialFuzzyPath = pathUtil.join(config.partialsPath, partialName)
				#partial.document ?= docpad.getCollection('partials').fuzzyFindOne(partialFuzzyPath)
				collection = docpad.getCollection('partials')
				config.partialPaths.forEach (partialPath) ->
					partialFuzzyPath = pathUtil.join(partialPath, partialName)
					partial.document ?= collection.fuzzyFindOne(partialFuzzyPath)
					return

				unless partial.document
					# Partial was not found
					message = util.format(locale.partialNotFound, partialName)
					err = new Error(message)
					partial.err ?= err
					return message

				# Prepare the initial partial data
				partial.data = {}

				# If no object is provided then provide the current template data as the first thing
				# if the performance first option is set to false (the default)
				if config.performanceFirst is false
					objs.unshift(@)  unless objs[0] in [false, @]

				# Cycle through the objects merging them together
				# ignore boolean values
				for obj in objs
					if obj and (obj isnt true)
						extendr.extend(partial.data, obj)
						# ^ why do we just do a shallow extend here instead of a deep extend?

				# Prepare our partial id
				partial.path = partial.document.getFilePath()
				partial.cacheId = partial.document.id
				partial.id = Math.random() # require('crypto').createHash('md5').update(partial.cacheId+'|'+JSON.stringify(partial.data)).digest('hex')
				partial.container = '[partial:'+partial.id+']'

				# Check if a partial with this id already exists!
				if me.foundPartials[partial.id]
					return partial.container

				# Store the partial
				me.foundPartials[partial.id] = partial

				# Create the task for our partial
				partial.task = new Task "renderPartial: #{partial.path}", (complete) ->
					me.renderPartial partial, (err, result) ->
						partial.err ?= err
						partial.result = partial.err?.toString() ? result ? '???'
						return complete(partial.err)

				# Return the container
				return partial.container

			# Chain
			@

		# Render the Document
		# Render our partials
		renderDocument: (opts,next) ->
			# Prepare
			{templateData, file} = opts

			# Check
			partialContainerRegex = /\[partial:([^\]]+)\]/g
			partialContainers = (opts.content or '').match(partialContainerRegex) or []
			return next()  if partialContainers.length is 0
			filePath = file.getFilePath()

			# Prepare
			me = @
			tasks = new TaskGroup("Partials for #{filePath}", concurrency:0).done (err) ->
				# Replace containers with results
				opts.content = opts.content.replace partialContainerRegex, (match, partialId) ->
					# Fetch partial
					partial = me.foundPartials[partialId]

					# Return result
					return partial.result

				# Complete
				return next(err)

			# Wait for found partials to complete rendering
			partialContainers.forEach (partialContainer) ->
				# Fetch partial
				partialId = partialContainer.replace(partialContainerRegex, '$1')
				partial = me.foundPartials[partialId]

				# Wait for all the partials to complete rendering
				tasks.addTask(partial.task)  if partial.task

			# Run the tasks
			tasks.run()

			# Chain
			@

		# Generate After
		# Reset the found partials after each generate, otherwise it will get very big
		generateAfter: ->
			@foundPartials = {}
			@partialsCache = {}
