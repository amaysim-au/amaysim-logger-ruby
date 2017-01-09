require 'active_support/concern'
require_relative 'correlation_id_helper'

class AmaysimLogger
  module RailsControllerHelper
    extend ActiveSupport::Concern
    include CorrelationIdHelper

    included do
      around_action :log_request if defined? ActionController::Base
    end

    def log_request
      append_to_log(request_id: request.uuid,
                    ip: request.remote_ip,
                    user_agent: request.headers['HTTP_USER_AGENT'],
                    endpoint: request.url,
                    correlation_id: correlation_id)
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
