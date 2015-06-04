require "sinatra/base"
require "rack/parser"
require "./deploy_worker"

class DeployService < Sinatra::Base
  GITHUB_SECRET = ENV.fetch('GITHUB_SECRET')
  WHITELISTED_OWNERS = %w[bemurphy codegangsta Kajabi]

  use Rack::Parser

  def verify_signature(payload_body)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha1'), GITHUB_SECRET,
      payload_body
    )

    unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
      halt 403, "Signatures didn't match!"
    end
  end

  def verify_whitelisted_repository(full_name)
    unless WHITELISTED_OWNERS.any? {|o| full_name.to_s.start_with?("#{o}/")}
      halt 403, "Forbidden repository"
    end
  end

  post "/push" do
    request.body.rewind
    payload_body = request.body.read
    verify_signature(payload_body)
    verify_whitelisted_repository(params["repository"]["full_name"])

    if request.env["HTTP_X_GITHUB_EVENT"] == "push"
      git_url      = params["repository"]["git_url"]
      project_name = params["repository"]["name"]

      DeployWorker.perform_async(git_url, project_name)

      "ok"
    else
      halt 422, "Unhandled event type"
    end
  end
end
