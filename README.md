# Scanty, a really small blog

## Overview

Scanty is blogging software. Software for my blog, to be exact:
<http://markwithout.heroku.com>

It is not a blogging engine, but it's small and easy to modify, so it could be
the starting point for your blog, too.

## Features

* Posts (shock!)
* Tags
* Markdown (via Maruku)
* Ruby code syntax highlighting (via Syntax)
* Atom feed
* Comments via Disqus
* Web framework = Sinatra
* ORM = Sequel

## Dependencies

	$ gem install sinatra sequel sinatra-sequel maruku

## Setup

The Blog config struct is loaded via heroku config vars or an optional config.yml
file you can include in the root directory with the appropriate hash.

Then run the server:

	$ ruby main.rb

And visit: <http://localhost:4567>

Log in with the password you provided in the Blog struct, then click New Post. The 
rest should be self-explanatory.

## Comments

If you wish to activate comments, create an account and enter the website shortname 
as the `:disqus_shortname` value in the Blog config struct.

## Import data

Christopher Swenson has a Wordpress importer: <http://github.com/swenson/scanty_wordpress_import>

Other kinds of data can be imported easily, take a look at the rake task :import for an 
example of loading from a YAML file with field names that match the database schema.

## Meta

This project hasn't been maintained in about a year, so I restored it back to life. In the midst
of restoration, I made it compatible with the latest Sinatra v1.0 and gave it a lighter theme.

* Written by: Adam Wiggins
* Patches contributed by: Christopher Swenson, S. Brent Faulkner, and Stephen Eley
* Released under the MIT License: <http://www.opensource.org/licenses/mit-license.php>
* <http://github.com/adamwiggins/scanty>
* <http://adam.blog.heroku.com>

