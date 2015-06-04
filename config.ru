require "./server"
require 'sidekiq/web'

run Rack::URLMap.new('/' => Server, '/sidekiq' => Sidekiq::Web)
