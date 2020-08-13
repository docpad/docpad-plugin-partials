<!-- TITLE/ -->

<h1>Partials Plugin for DocPad</h1>

<!-- /TITLE -->


<!-- BADGES/ -->

<span class="badge-travisci"><a href="http://travis-ci.com/docpad/docpad-plugin-partials" title="Check this project's build status on TravisCI"><img src="https://img.shields.io/travis/com/docpad/docpad-plugin-partials/master.svg" alt="Travis CI Build Status" /></a></span>
<span class="badge-npmversion"><a href="https://npmjs.org/package/docpad-plugin-partials" title="View this project on NPM"><img src="https://img.shields.io/npm/v/docpad-plugin-partials.svg" alt="NPM version" /></a></span>
<span class="badge-npmdownloads"><a href="https://npmjs.org/package/docpad-plugin-partials" title="View this project on NPM"><img src="https://img.shields.io/npm/dm/docpad-plugin-partials.svg" alt="NPM downloads" /></a></span>
<span class="badge-daviddm"><a href="https://david-dm.org/docpad/docpad-plugin-partials" title="View the status of this project's dependencies on DavidDM"><img src="https://img.shields.io/david/docpad/docpad-plugin-partials.svg" alt="Dependency Status" /></a></span>
<span class="badge-daviddmdev"><a href="https://david-dm.org/docpad/docpad-plugin-partials#info=devDependencies" title="View the status of this project's development dependencies on DavidDM"><img src="https://img.shields.io/david/dev/docpad/docpad-plugin-partials.svg" alt="Dev Dependency Status" /></a></span>
<br class="badge-separator" />
<span class="badge-githubsponsors"><a href="https://github.com/sponsors/balupton" title="Donate to this project using GitHub Sponsors"><img src="https://img.shields.io/badge/github-donate-yellow.svg" alt="GitHub Sponsors donate button" /></a></span>
<span class="badge-patreon"><a href="https://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-liberapay"><a href="https://liberapay.com/bevry" title="Donate to this project using Liberapay"><img src="https://img.shields.io/badge/liberapay-donate-yellow.svg" alt="Liberapay donate button" /></a></span>
<span class="badge-buymeacoffee"><a href="https://buymeacoffee.com/balupton" title="Donate to this project using Buy Me A Coffee"><img src="https://img.shields.io/badge/buy%20me%20a%20coffee-donate-yellow.svg" alt="Buy Me A Coffee donate button" /></a></span>
<span class="badge-opencollective"><a href="https://opencollective.com/bevry" title="Donate to this project using Open Collective"><img src="https://img.shields.io/badge/open%20collective-donate-yellow.svg" alt="Open Collective donate button" /></a></span>
<span class="badge-crypto"><a href="https://bevry.me/crypto" title="Donate to this project using Cryptocurrency"><img src="https://img.shields.io/badge/crypto-donate-yellow.svg" alt="crypto donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<!-- /BADGES -->


This plugin provides [DocPad](https://docpad.org) with Partials. Partials are documents which can be inserted into other documents, and are also passed by the docpad rendering engine.

## Usage

Create the `src/partials` directory, and place any partials you want to use in there.

Then call the new `partial(filename, objs...)` template helper to include the partial. The object arguments are optional, and can be used to send custom data to the partial's template data. Setting the first object argument to `false` will not send over the template data by default.

### Examples

Lets say we have the partial `src/partials/hello.html.eco` that includes:

```html
Hello <%=@name or 'World'%> Welcome to <%= @site?.name or 'My Site' %>
```

And a [docpad configuration file](http://docpad.org) file that includes:

```coffee
templateData:
	site:
		name: "Ben's Awesome Site"
```

We could then render via a `src/documents/index.html.eco` document in these different ways:

```html
<!-- Include the rendered contents of `src/partials/my-partial` file -->
<!-- and send over the template data -->
<%- @partial('hello') %>
<!-- gives us:
Hello World
Welcome to Ben's Awesome Site
-->

<!-- Include the rendered contents of `src/partials/my-partial` file -->
<!-- and send over the template data -->
<!-- and send over our own custom template data -->
<%- @partial('hello', {name:'Ben'}) %>
<!-- gives us:
Hello Ben
Welcome to Ben's Awesome Site
-->

<!-- Include the rendered contents of `src/partials/my-partial` file -->
<!-- and DO NOT send over the template data -->
<%- @partial('hello', false) %>
<!-- gives us:
Hello World
Welcome to My Site
-->

<!-- Include the rendered contents of `src/partials/my-partial` file -->
<!-- and DO NOT send over the template data -->
<!-- and send over ONLY our own custom template data -->
<%- @partial('hello', false, {name:'Ben'}) %>
<!-- gives us:
Hello Ben
Welcome to My Site
-->

<!-- Include the rendered contents of `src/partials/my-partial` file -->
<!-- and DO NOT send over the template data -->
<!-- and send over our own custom template data with the template data site property -->
<%- @partial('hello', false, {site:{name:@site.name}}, {name:'Ben'}) %>
<!-- gives us:
Hello Ben
Welcome to Ben's Awesome Site
-->
```

### Notes

To increase performance it is recommended you only include the exact template data variables that you need - this is because sending over all the template data can be a costly process as we much destroy all references (do a deep clone) to avoid reference conflicts and over-writes between each render - so sending over as little / as specific data as possible means less reference destroying which means faster processing.

If your partial only needs to be rendered once per (re)generation then you can specify `cacheable: true` in the partial's meta data, doing so greatly improves performance.

Partials actually render asynchronously, when you call `<%- @partial('hello') %>` you'll actually get back something a temporary placeholder like `[partial:0.1290219301293]` while your template is rendering, then once your template has rendered, and once all the partials have rendered, we will then go through and replace these placeholder values with the correct content. We must do this as template rendering is a synchronous process whereas document rendering is an asynchronous process. [More info here.](https://github.com/docpad/docpad-plugin-partials/issues/12)

### Compatibility

-   Versions 2.8.0 and above DO send the template data by default. You can turn this off by using `false` as the first object argument or by setting `performanceFirst: true` in your plugin's configuration options.

-   Versions below 2.8.0 DO NOT send the template data by default. You must add it by using `@` or `this` as the first object argument like so: `<%- @partial('my-partial', @) %>`

<!-- INSTALL/ -->

<h2>Install</h2>

Install this DocPad plugin by entering <code>docpad install partials</code> into your terminal.

<!-- /INSTALL -->


<!-- HISTORY/ -->

<h2>History</h2>

<a href="https://github.com/docpad/docpad-plugin-partials/blob/master/HISTORY.md#files">Discover the release history by heading on over to the <code>HISTORY.md</code> file.</a>

<!-- /HISTORY -->


<!-- CONTRIBUTE/ -->

<h2>Contribute</h2>

<a href="https://github.com/docpad/docpad-plugin-partials/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /CONTRIBUTE -->


<!-- BACKERS/ -->

<h2>Backers</h2>

<h3>Maintainers</h3>

These amazing people are maintaining this project:

<ul><li><a href="https://github.com/balupton">Benjamin Lupton</a> — <a href="https://github.com/docpad/docpad-plugin-partials/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository docpad/docpad-plugin-partials">view contributions</a></li></ul>

<h3>Sponsors</h3>

No sponsors yet! Will you be the first?

<span class="badge-githubsponsors"><a href="https://github.com/sponsors/balupton" title="Donate to this project using GitHub Sponsors"><img src="https://img.shields.io/badge/github-donate-yellow.svg" alt="GitHub Sponsors donate button" /></a></span>
<span class="badge-patreon"><a href="https://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-liberapay"><a href="https://liberapay.com/bevry" title="Donate to this project using Liberapay"><img src="https://img.shields.io/badge/liberapay-donate-yellow.svg" alt="Liberapay donate button" /></a></span>
<span class="badge-buymeacoffee"><a href="https://buymeacoffee.com/balupton" title="Donate to this project using Buy Me A Coffee"><img src="https://img.shields.io/badge/buy%20me%20a%20coffee-donate-yellow.svg" alt="Buy Me A Coffee donate button" /></a></span>
<span class="badge-opencollective"><a href="https://opencollective.com/bevry" title="Donate to this project using Open Collective"><img src="https://img.shields.io/badge/open%20collective-donate-yellow.svg" alt="Open Collective donate button" /></a></span>
<span class="badge-crypto"><a href="https://bevry.me/crypto" title="Donate to this project using Cryptocurrency"><img src="https://img.shields.io/badge/crypto-donate-yellow.svg" alt="crypto donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<h3>Contributors</h3>

These amazing people have contributed code to this project:

<ul><li><a href="https://github.com/balupton">Benjamin Lupton</a> — <a href="https://github.com/docpad/docpad-plugin-partials/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository docpad/docpad-plugin-partials">view contributions</a></li>
<li><a href="http://takitapart.com">Bob VanderClay</a></li>
<li><a href="https://github.com/bobvanderclay">Bob VanderClay</a> — <a href="https://github.com/docpad/docpad-plugin-partials/commits?author=bobvanderclay" title="View the GitHub contributions of Bob VanderClay on repository docpad/docpad-plugin-partials">view contributions</a></li>
<li><a href="https://github.com/Delapouite">Bruno Heridet</a> — <a href="https://github.com/docpad/docpad-plugin-partials/commits?author=Delapouite" title="View the GitHub contributions of Bruno Heridet on repository docpad/docpad-plugin-partials">view contributions</a></li>
<li><a href="https://github.com/iredmedia">Kevin Redman</a> — <a href="https://github.com/docpad/docpad-plugin-partials/commits?author=iredmedia" title="View the GitHub contributions of Kevin Redman on repository docpad/docpad-plugin-partials">view contributions</a></li>
<li><a href="https://github.com/patocallaghan">Pat O'Callaghan</a> — <a href="https://github.com/docpad/docpad-plugin-partials/commits?author=patocallaghan" title="View the GitHub contributions of Pat O'Callaghan on repository docpad/docpad-plugin-partials">view contributions</a></li>
<li><a href="https://github.com/patuf">patuf</a> — <a href="https://github.com/docpad/docpad-plugin-partials/commits?author=patuf" title="View the GitHub contributions of patuf on repository docpad/docpad-plugin-partials">view contributions</a></li>
<li><a href="https://github.com/vsopvsop">vsopvsop</a> — <a href="https://github.com/docpad/docpad-plugin-partials/commits?author=vsopvsop" title="View the GitHub contributions of vsopvsop on repository docpad/docpad-plugin-partials">view contributions</a></li></ul>

<a href="https://github.com/docpad/docpad-plugin-partials/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /BACKERS -->


<!-- LICENSE/ -->

<h2>License</h2>

Unless stated otherwise all works are:

<ul><li>Copyright &copy; 2012+ <a href="http://bevry.me">Bevry Pty Ltd</a></li></ul>

and licensed under:

<ul><li><a href="http://spdx.org/licenses/MIT.html">MIT License</a></li></ul>

<!-- /LICENSE -->
