require 'rubygems'
require 'bundler'
require 'sass/plugin/rack'
require 'tilt/erb'


Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

Bundler.require

require './app'
run Sinatra::Application