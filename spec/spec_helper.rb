# CodeClimate relative stuff
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'simplecov'
SimpleCov.start

require 'coveralls'
Coveralls.wear!

require 'rspec'
require 'docker'
require 'docker/testing'
require 'support/stdout'
require 'support/hash'
require 'support/shared_stuff/shared_container'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #  --seed 1234
  config.order = 'random'
end

# Disable testing mode
Docker::Testing.fake!
