web: bundle exec thin -p $PORT -e $RACK_ENV -R ./config.ru start
worker: bundle exec sidekiq -c 5 -q default,1 -r ./deploy_worker.rb
