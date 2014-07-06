cur = File.dirname(__FILE__)
load File.absolute_path(File.join(cur, "../bootstrap.rb"))

Bundler.setup :default, :test
require 'rspec'
require 'rspec/mocks'

require 'pry'

ENV["LOG"] = "NONE"

this_root = File.dirname(__FILE__)
SPEC_ROOT = File.expand_path(this_root, "../")

def create_asset(uri_s, type = "image")
  SimpleCrawler::Models::Asset.new Addressable::URI.parse(uri_s), type
end

def create_link(uri_s)
  SimpleCrawler::Models::Link.new Addressable::URI.parse(uri_s)
end

def create_content(uri_s, assets = nil, links = nil)
  SimpleCrawler::Models::ContentInfo.new uri_s, assets, links
end

RSpec.configure do |config|
  config.mock_with :rspec

  config.raise_errors_for_deprecations!
end
