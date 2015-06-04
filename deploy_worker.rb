require "git"
require "sidekiq"

class DeployWorker
  DEPLOY_SCRIPT = "deploy.sh"

  include Sidekiq::Worker

  def perform(git_url, project_name)
    Dir.mktmpdir do |dir|
      repo_dir = File.join(dir, project_name)

      Git.clone(git_url, project_name, path: dir)

      unless File.exists?(File.join(repo_dir, DEPLOY_SCRIPT))
        raise "#{DEPLOY_SCRIPT} does not exist for project_name #{project_name}"
      end

      Bundler.with_clean_env do
        Dir.chdir repo_dir do
          `./#{DEPLOY_SCRIPT}`
        end
      end
    end
  end
end
