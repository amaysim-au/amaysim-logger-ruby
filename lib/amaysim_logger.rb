require 'amaysim_logger/helpers'
require 'amaysim_logger/logger'
require 'amaysim_logger/rails_controller_helper'
require 'amaysim_logger/event_handler'
require 'active_support/core_ext/module/delegation'

class AmaysimLogger
  class << self
    attr_writer :logger

    def logger
      @logger ||= AmaysimLogger::Logger.new(STDOUT)
    end

    delegate :info, :debug, :warn, :error, :unknown, :log_context,
             :log_context=, :add_to_log_context, :formatter, :formatter=,
             :level, :level=, to: :logger
  end
end

require 'amaysim_logger/railtie' if defined? Rails
