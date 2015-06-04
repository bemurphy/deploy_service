require "./deploy_service"
require 'sidekiq/web'

run Rack::URLMap.new('/' => DeployService, '/sidekiq' => Sidekiq::Web)
