cur = File.dirname(__FILE__)
load File.absolute_path(File.join(cur, "../bootstrap.rb"))

Bundler.setup :default, :test
require 'rspec'
require 'rspec/mocks'

require 'pry'

RSpec.configure do |config|
  config.mock_with :rspec

  config.raise_errors_for_deprecations!
end
