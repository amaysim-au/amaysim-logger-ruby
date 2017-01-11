require 'active_support/logger'
require 'active_support/core_ext/module/delegation'
require 'request_store'

class AmaysimLogger
  class << self
    def info(msg = nil, _progname = nil)
      log(msg, :info, block_given? ? -> { yield } : nil)
    end

    def debug(msg = nil, _progname = nil)
      log(msg, :debug, block_given? ? -> { yield } : nil)
    end

    def warn(msg = nil, _progname = nil)
      log(msg, :warn, block_given? ? -> { yield } : nil)
    end

    def error(msg = nil, _progname = nil)
      log(msg, :error, block_given? ? -> { yield } : nil)
    end

    def unknown(msg = nil, _progname = nil)
      log(msg, :unknown, block_given? ? -> { yield } : nil)
    end

    def add_to_log_context(params = {})
      context_is_a_hash = log_context.is_a?(Hash)
      new_params = log_context.merge(params) if context_is_a_hash
      self.log_context = context_is_a_hash ? new_params : params
    end

    def log_context
      RequestStore[:log_context] ||= {}
    end

    def log_context=(context)
      RequestStore[:log_context] = context
    end

    def logger
      @logger ||= ActiveSupport::Logger.new(STDOUT)
    end

    delegate :level, :level=, to: :logger
    delegate :formatter, :formatter=, to: :logger
    delegate :info?, :debug?, :warn?, :error?, :unknown?, to: :logger

    private

    def log(log_msg, log_level, execute)
      msg, params = msg_and_attributes(log_msg)
      log_params = create_log_params(msg, params)
      log_with = ->(log_content) { logger.send(log_level, log_content) }
      if execute
        log_with_duration(log_params, log_with, execute)
      else
        log_with.call(format_params(log_params))
      end
    end

    def msg_and_attributes(log_msg)
      if log_msg.is_a?(Hash)
        [log_msg.delete(:msg), log_msg]
      else
        [log_msg.to_s, {}]
      end
    end

    def log_timestamp(time = Time.now)
      "#{time} #{time.zone}"
    end

    def create_log_params(msg, params)
      timestamped_message = { msg: msg, log_timestamp: log_timestamp }
      timestamped_message.merge(log_context).merge(params)
    end

    # rubocop:disable Metrics/MethodLength
    def log_with_duration(log_params, log_with, execute)
      start_time = Time.now
      log_params[:start_time] = log_timestamp(start_time)
      execute.call
    rescue StandardError => e
      log_params[:exception] = e.class
      log_params[:exception_msg] = e
      raise e
    ensure
      end_time = Time.now
      log_params[:end_time] = log_timestamp(end_time)
      log_params[:duration] = (end_time - start_time)
      log_with.call(format_params(log_params))
    end

    def format_params(params)
      params.to_json
    end
  end
end
