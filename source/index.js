/* eslint-disable class-methods-use-this */
// @ts-nocheck
'use strict'

// Export Plugin
module.exports = function (BasePlugin) {
	// Requires
	const extendr = require('extendr')
	const { Task, TaskGroup } = require('taskgroup')
	const pathUtil = require('path')
	const { format } = require('util')

	// Define Plugin
	return class PartialsPlugin extends BasePlugin {
		// Plugin Name
		get name() {
			return 'partials'
		}

		// Default Configuration
		get initialConfig() {
			return {
				partialPaths: ['partials'],
				collectionName: 'partials',
				performanceFirst: false,
			}
		}

		// Variables
		constructor(...args) {
			super(...args)

			this.locale = {
				addingPartial: 'Adding partial: %s',
				partialNotFound:
					'The partial "%s" was not found, as such it will not be rendered.',
				renderPartial: 'Rendering partial: %s',
				renderedPartial: 'Rendered partial: %s',
				renderPartialFailed: 'Rendering partial failed: %s. The error follows:',
			}

			this.foundPartials = {}
			this.partialsCache = {}
		}

		// -----------------------------
		// Initialize

		// Prepare our Configuration
		setConfig(...args) {
			// Apply
			super.setConfig(...args)

			// Prepare
			const config = this.getConfig()
			const { docpad } = this

			// ensure config name backward compatibility
			config.partialPaths = config.partialsPath || config.partialPaths

			// ensure the partialPaths is an array
			if (!Array.isArray(config.partialPaths)) {
				config.partialPaths = [config.partialPaths]
			}

			// Adjust
			config.partialPaths.forEach(function (partialPath, index) {
				config.partialPaths[index] = pathUtil.resolve(
					docpad.getPath('source'),
					partialPath
				)
			})
		}

		// -----------------------------
		// Events

		// Populate Collections
		populateCollections(opts, next) {
			// Prepare
			const config = this.getConfig()
			const { docpad } = this

			// Load our partials directory
			let exited = false
			config.partialPaths.forEach(function (partialPath) {
				docpad.parseDocumentDirectory({ path: partialPath }, function (
					err,
					results
				) {
					if (err) {
						exited = true
						next(err)
					}
				})
			})

			// if we didn't exist from the loop, then exit here
			if (exited === false) {
				next()
			}
		}

		// Extend Collections
		extendCollections(opts) {
			// Prepare
			const config = this.getConfig()
			const { docpad, locale } = this
			const database = docpad.getDatabase()

			// Add our partials collection
			docpad.setCollection(
				config.collectionName,
				database
					.createLiveChildCollection()
					.setQuery('isPartial', {
						$or: {
							isPartial: true,
							fullPath: {
								$startsWith: config.partialPaths,
							},
						},
					})
					.on('add', function (model) {
						docpad.log(
							'debug',
							format(locale.addingPartial, model.getFilePath())
						)
						model.setDefaults({
							isPartial: true,
							render: false,
							write: false,
						})
					})
			)
		}

		// -----------------------------
		// Rendering

		// Render Partial
		// Render a partial asynchronously
		// next(err,result,document)
		renderPartial(partial, next) {
			// Prepare
			const { docpad, partialsCache } = this
			let result

			// Check if our partial is cacheable
			let cacheable = partial.document.getMeta().get('cacheable')
			if (cacheable == null) cacheable = false
			else if (cacheable) {
				result = partialsCache[partial.cacheId]
			}

			// Got from cache, so use that
			if (result != null) {
				return next(null, result)
			}

			// Render
			docpad.renderDocument(
				partial.document,
				{ templateData: partial.data },
				function (err, result, document) {
					// Check
					if (err) return next(err)

					// Cache
					if (cacheable) {
						partialsCache[partial.cacheId] = result
					}

					// Forward
					return next(null, result == null ? null : result)
				}
			)
		}

		// Extend Template Data
		// Inject our partial methods
		extendTemplateData({ templateData }) {
			// Prepare
			const me = this
			const { docpad, locale } = this

			// Apply
			templateData.partial = function (partialName, ...objs) {
				// Reference others
				const config = me.getConfig()
				if (this.referencesOthers) {
					this.referencesOthers()
				}

				// Prepare
				// const file = this.documentModel
				const partial = {}

				// Fetch our partial
				// partialFuzzyPath = pathUtil.join(config.partialsPath, partialName)
				// partial.document ?= docpad.getCollection('partials').fuzzyFindOne(partialFuzzyPath)
				const collection = docpad.getCollection('partials')
				config.partialPaths.forEach(function (partialPath) {
					const partialFuzzyPath = pathUtil.join(partialPath, partialName)
					if (!partial.document) {
						partial.document = collection.fuzzyFindOne(partialFuzzyPath)
					}
				})

				// partial not found
				if (!partial.document) {
					const message = format(locale.partialNotFound, partialName)
					const err = new Error(message)
					if (partial.err == null) {
						partial.err = err
					}
					return message
				}

				// Prepare the initial partial data
				partial.data = {}

				// If no object is provided then provide the current template data as the first thing
				// if the performance first option is set to false (the default)
				if (config.performanceFirst === false) {
					if ([false, this].includes(objs[0]) === false) {
						objs.unshift(this)
					}
				}

				// Cycle through the objects merging them together
				// ignore boolean values
				for (const obj of objs) {
					if (obj && obj !== true) {
						extendr.extend(partial.data, obj)
						// ^ why do we just do a shallow extend here instead of a deep extend?
					}
				}

				// Prepare our partial id
				partial.path = partial.document.getFilePath()
				partial.cacheId = partial.document.id
				partial.id = Math.random() // require('crypto').createHash('md5').update(partial.cacheId+'|'+JSON.stringify(partial.data)).digest('hex')
				partial.container = '[partial:' + partial.id + ']'

				// Check if a partial with this id already exists!
				if (me.foundPartials[partial.id]) {
					return partial.container
				}

				// Store the partial
				me.foundPartials[partial.id] = partial

				// Create the task for our partial
				partial.task = new Task(`renderPartial: ${partial.path}`, function (
					complete
				) {
					me.renderPartial(partial, function (err, result) {
						if (partial.err == null) partial.err = err
						if (partial.err) {
							partial.result = partial.err.toString()
						} else if (result) {
							partial.result = result
						} else {
							partial.result = '???'
						}
						return complete(partial.err)
					})
				})

				// Return the container
				return partial.container
			}
		}

		// Render the Document
		// Render our partials
		renderDocument(opts, next) {
			// Prepare
			const me = this
			const { templateData, file } = opts

			// Check
			const partialContainerRegex = /\[partial:([^\]]+)\]/g
			const partialContainers =
				(opts.content || '').match(partialContainerRegex) || []
			if (partialContainers.length === 0) {
				return next()
			}
			const filePath = file.getFilePath()

			// Prepare
			const tasks = new TaskGroup(`Partials for ${filePath}`, {
				concurrency: 0,
			}).done(function (err) {
				// Replace containers with results
				opts.content = opts.content.replace(partialContainerRegex, function (
					match,
					partialId
				) {
					// Fetch partial
					const partial = me.foundPartials[partialId]

					// Return result
					return partial.result
				})

				// Complete
				return next(err)
			})

			// Wait for found partials to complete rendering
			partialContainers.forEach(function (partialContainer) {
				// Fetch partial
				const partialId = partialContainer.replace(partialContainerRegex, '$1')
				const partial = me.foundPartials[partialId]

				// Wait for all the partials to complete rendering
				if (partial.task) {
					tasks.addTask(partial.task)
				}
			})

			// Run the tasks
			tasks.run()
		}

		// Generate Before
		// Reset the found partials before each generate, otherwise it will get very big
		generateBefore() {
			this.foundPartials = {}
			this.partialsCache = {}
		}

		// Generate After
		// Reset the found partials after each generate, otherwise it will linger uncessarily
		generateAfter() {
			this.foundPartials = {}
			this.partialsCache = {}
		}
	}
}
