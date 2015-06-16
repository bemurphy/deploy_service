require "./deploy_result"
require "git"
require "json"
require "open3"
require "sidekiq"

Git.configure do |config|
  config.git_ssh = File.join(File.dirname(__FILE__), "git_ssh.sh")
end

class DeployWorker
  DEPLOY_SCRIPT = "deploy.sh"

  include Sidekiq::Worker

  def perform(payload)
    @payload      = payload
    @ssh_url      = @payload["repository"]["ssh_url"]
    @project_name = @payload["repository"]["name"]

    Dir.mktmpdir do |dir|
      repo_dir = File.join(dir, @project_name)

      Git.clone(@ssh_url, @project_name, path: dir)

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
