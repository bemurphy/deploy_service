require "redis"

class DeployResult
  attr_accessor :output, :error, :exitstatus, :created_at, :payload

  def self.create(attributes = {})
    with_redis do |redis|
      ["deploy_results", attributes[:git_url]].each do |key|
        redis.lpush(key, JSON.dump(attributes))
        redis.ltrim(key, 0, 50)
      end
      redis.zadd("deploy_git_urls", Time.now.to_i, attributes[:git_url])
    end
  end

  def self.with_redis
    begin
      url   = ENV.fetch("REDIS_URL", "redis://localhost:6379")
      redis = Redis.new(url: url)
      yield redis
    ensure
      redis.disconnect!
    end
  end

  def self.all(key, limit = 0)
    with_redis do |redis|
      redis.lrange(key, 0, limit - 1).map {|raw| new(JSON[raw]) }
    end
  end

  def self.all_git_urls
    with_redis do |redis|
      redis.zrange("deploy_git_urls", 0, 1).sort
    end
  end

  def initialize(attributes = {})
    attributes.each do |k, v|
      self.send(:"#{k}=", v)
    end
  end

  def git_url
    payload ? payload["repository"]["git_url"].to_s : ""
  end

  def success?
    exitstatus == 0
  end

  def error?
    !success
  end

  def git_sha
    payload && payload["head_commit"]["id"]
  end

  def git_short_sha
    git_sha.to_s[0, 10]
  end

  def project_name
    payload && payload["repository"]["full_name"]
  end

  def repo_url
    git_url.sub('git:', 'https:').sub(/\.git\z/, '')
  end
end
