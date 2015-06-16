web: bundle exec rackup config.ru -p $PORT
worker: bundle exec sidekiq -c -q default,1 -r ./deploy_worker.rb
