cur = File.dirname(__FILE__)
load File.absolute_path(File.join(cur, "../bootstrap.rb"))

Bundler.setup :default, :test
require 'rspec'
require 'rspec/mocks'

require 'pry'

this_root = File.dirname(__FILE__)
SPEC_ROOT = File.expand_path(this_root, "../")

RSpec.configure do |config|
  config.mock_with :rspec

  config.raise_errors_for_deprecations!
end
