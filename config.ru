require 'rubygems'
require 'sinatra'

set :views, File.join( File.dirname(__FILE__), 'views' )
set :run, false
set :environment, ENV['RACK_ENV']

require 'main'
run Sinatra::Application
