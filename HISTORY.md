# History

## v2.11.0 2017 April 17
- Updated dependencies

## v2.10.0 2017 April 17
- Updated base files

## v2.9.2 2015 March 5
- Updated dependencies

## v2.9.1 2014 May 7
- Minor improvements to make debugging easier

## v2.9.0 2014 February 26
- Now supports multiple partial paths
	- Thanks to [pflannery](https://github.com/pflannery) for [pull request #14](https://github.com/docpad/docpad-plugin-partials/pull/14)

## v2.8.1 2013 November 6
- Fixed error reporting when a partial breaks (regression since always???)
- Partials now render inside the `renderDocument` event, rather than any random time
- Updated dependencies

## v2.8.0 2013 August 23
- Template data is now sent with partial calls by default, and can be turned off by setting the first object you pass the the partial as `false`, e.g. `<%- @partial('hello', false, blah) %>`
	- This has been documented quite thoroughly now in the README
	- This backwards compatibility break is due to the incredibly high amount of "user error" issues not sending the template data by default causes. In hindsight, it has become apparent to us that sacrificing docpad performance time for developer performance time and developer happiness is a far better trade. Caring about performance should come secondary to happiness. Not before it.
	- For those whom do care about performance, you should update all your existing partial calls to make use of the new first `false` object practice, or if you are too lazy set `performanceFirst: true` in the plugin's configuration options.

## v2.7.2 2013 July 30
- You can now customise the collection name via the `collectioName` option
- Updated some older docpad api conventions for their newer equilevants

## v2.7.1 2013 July 25
- Updated for DocPad v6.46.2

## v2.7.0 2013 July 23
- Updated for DocPad v6.46

## v2.6.3 2013 May 28
- Fixed `Cannot call method 'match' of null`

## v2.6.2 2013 April 17
- Fixed cacheable partials (broke in v2.6.0)

## v2.6.1 2013 April 6
- Fixed `???` being outputted for empty partials (bug introduced in v2.6.0)
	- Closes [issue #5](https://github.com/docpad/docpad-plugin-partials/issues/5) and [pull request #6](https://github.com/docpad/docpad-plugin-partials/pull/6) thanks to [Bob VanderClay](https://github.com/takitapart) and [Bruno Héridet](https://github.com/Delapouite)

## v2.6.0 2013 April 6
- Partials now begin rendering as soon as we receive them
- Dependency upgrades

## v2.5.2 2013 April 5
- Dependency upgrades

## v2.5.1 2013 April 1
- Dependency upgrades

## v2.5.0 2013 March 7
- DocPad v6.24.0 support
- Repackaged
- Dependency upgrades
	-  `bal-util` from 1.15.x to ~1.16.8
	-  `coffee-script` from 1.4.x to ~1.4.0

## v2.4.0 2012 December 15
- Removed the possibility of name collisions when storing partial info
- You can now cache a partial by setting `cacheable: true` in the partial's meta data
	- Doing this will only render it once per (re)generation. Cache is cleared after each (re)generation.

## v2.3.0 2012 November 23
- New way of doing partials
	- Should be faster
	- Should support watching better
	- Supports fuzzy matching
- Thanks to [ashnur](https://github.com/ashnur) for [issue #283](https://github.com/bevry/docpad/issues/283)

## v2.2.1 2012 November 6
- Fixed memory leak (didn't clean up after generations, so regenerations would take longer and longer)
	- Fixes [#335](https://github.com/bevry/docpad/issues/335)

## v2.2.0 2012 October 7
- `@partial` signature now changed from `@partial(name,data)` to `@partial(name,objs...)`
	- If multiple objects are specified, they will be shallow-y merged into an empty object
	- This allows you to do things like `@partial('blah',@,{blah:'blah'})` to extend the partial `blah` with the template data and some custom partial data

## v2.1.2 2012 August 10
- Re-added markdown files to npm distribution as they are required for the npm website

## v2.1.1 2012 July 8
- Moved the insertion of the partial template helper into the new `extendTemplateData` event

## v2.1.0 2012 July 8
- Fixed path exists warning
- Updated for DocPad 6.1

## v1.0.1 2012 May 5
- Updated for DocPad v5.2
- Partials are now created with `createDocument` instead of `createPartial` which has been removed
- Partials which aren't found will now throw a warning

## v1.0.0 2012 April 14
- Updated for DocPad v5.0
- Fixed multiple partials on the same document bug

## v0.1.0 2012 March 31
- Initial working version for [Benjamin Lupton's Website](https://github.com/balupton/balupton.docpad)
