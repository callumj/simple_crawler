require 'bundler'

Bundler.setup

# LOAD path mod
$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'simple_crawler'