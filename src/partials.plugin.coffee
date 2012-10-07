# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	balUtil = require('bal-util')
	pathUtil = require('path')

	# Define Plugin
	class PartialsPlugin extends BasePlugin
		# Plugin Name
		name: 'partials'

		# Default Configuration
		config:
			partialsPath: 'partials'

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

			# Check the partial exists
			balUtil.exists partial.path, (exists) ->
				# If it doesn't, warn
				unless exists
					err = new Error("The partial [#{partial.name}] was not found, and as such will not be rendered.")
					return next(err)  if err

				# Render
				docpad.renderPath(partial.path, {templateData:partial.data}, next)

			# Chain
			@


		# -----------------------------
		# Events

		# Extend Template Data
		extendTemplateData: ({templateData}) ->
			# Prepare
			me = @
			@foundPartials = {}

			# Apply
			templateData.partial = (name,objs...) ->
				if objs.length >= 2
					objs.unshift({})
					data = balUtil.shallowExtendPlainObjects(objs...)
				else
					data = objs[0] ? {}
				return me.renderPartialSync(name,data)

			# Chain
			@


		# Render the Document
		renderDocument: (opts,next) ->
			# Prepare
			{templateData,file} = opts

			# Prepare
			me = @
			docpad = @docpad
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
					docpad.log 'debug', "Rendering partial: #{partial.name}"

					# Render
					me.renderPartial partial, (err,contentRendered) ->
						# Check
						if err
							# Warn
							docpad.warn("Rendering partial failed: #{partial.name}. The error follows:", err)

						# Replace container with the rendered content
						else
							# Log
							docpad.log 'debug', "Rendered partial: #{partial.name}"

							# Apply
							opts.content = opts.content.replace(partial.container,contentRendered)

						# Done
						return complete()

			# Fire the tasks together
			tasks.async()

			# Chain
			@