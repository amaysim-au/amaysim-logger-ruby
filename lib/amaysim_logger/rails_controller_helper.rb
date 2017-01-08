require 'active_support/concern'

class AmaysimLogger
  module RailsControllerHelper
    extend ActiveSupport::Concern

    included do
      around_action :log_request if defined? ActionController::Base
    end

    def log_request
      append_to_log(request_id: request.uuid,
                    ip: request.remote_ip,
                    user_agent: request.headers['HTTP_USER_AGENT'],
                    endpoint: request.url)
      AmaysimLogger.debug(msg: 'log_request', execute: lambda do
        yield
      end)
    end

    def append_to_log(params = {})
      AmaysimLogger.append_to_log(params)
    end
    alias add_to_request_store append_to_log
  end
end
