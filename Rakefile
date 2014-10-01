require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

RSpec::Core::RakeTask.new(:rspec)
Rubocop::RakeTask.new(:rubocop)

task default: :rspec

task :console do
  exec 'bundle exec pry -r kml_data_connector -I ./lib'
end

task :release do
  logger.info spec = `bundle exec rake rspec`
  logger.info '----'
  logger.info rubocop = `bundle exec rake rubocop`
  logger.info '----'

  if spec.include?(' 0 failures') && rubocop.include?(' no offenses detected')
    logger.info `bundle exec rake release`
  else
    logger.info '==> Something wrong happened!'
  end
end
