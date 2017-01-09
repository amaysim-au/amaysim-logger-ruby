require 'active_support/concern'
require 'active_support/core_ext/module/delegation'
require_relative 'correlation_id_helper'

class AmaysimLogger
  module RailsControllerHelper
    extend ActiveSupport::Concern
    include CorrelationIdHelper

    included do
      around_action :log_request
    end

    def log_request
      add_to_log_context(request_id: request.uuid,
                         ip: request.remote_ip,
                         user_agent: request.headers['HTTP_USER_AGENT'],
                         endpoint: request.url,
                         correlation_id: correlation_id)
      AmaysimLogger.debug(msg: 'log_request', execute: lambda do
        yield
      end)
    end

    delegate :add_to_log_context, to: AmaysimLogger
  end
end
