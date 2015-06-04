require "./deploy_result"
require "git"
require "json"
require "open3"
require "sidekiq"

class DeployWorker
  DEPLOY_SCRIPT = "deploy.sh"

  include Sidekiq::Worker

  def perform(payload)
    @payload      = payload
    @git_url      = @payload["repository"]["git_url"]
    @project_name = @payload["repository"]["name"]

    Dir.mktmpdir do |dir|
      repo_dir = File.join(dir, @project_name)

      Git.clone(@git_url, @project_name, path: dir)

      unless File.exists?(File.join(repo_dir, DEPLOY_SCRIPT))
        raise "#{DEPLOY_SCRIPT} does not exist for project_name #{@project_name}"
      end

      Bundler.with_clean_env do
        Dir.chdir repo_dir do
          @output, @err, @status = Open3.capture3("./#{DEPLOY_SCRIPT}")
          persist
          notify
        end
      end
    end
  end

  private

  def persist
    DeployResult.create(
      created_at: Time.now.utc,
      output: @output,
      error: @err,
      exitstatus: @status.exitstatus,
      payload: @payload
    )
  end

  def notify
    #TODO
  end
end
