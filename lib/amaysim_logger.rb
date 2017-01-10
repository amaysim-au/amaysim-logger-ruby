require 'active_support/logger'
require 'request_store'

class AmaysimLogger
  class << self
    def info(msg:, params: {})
      log(msg, params, :info, block_given? ? -> {yield} : nil)
    end

    def debug(msg:, params: {})
      log(msg, params, :debug, block_given? ? -> {yield} : nil)
    end

    def warn(msg:, params: {})
      log(msg, params, :warn, block_given? ? -> {yield} : nil)
    end

    def error(msg:, params: {})
      log(msg, params, :error, block_given? ? -> {yield} : nil)
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

    private

    def log(msg, params, log_level, execute)
      log_params = create_log_params(msg, params)
      log_with = ->(log_msg) { logger.send(log_level, log_msg) }
      if execute
        log_with_duration(log_params, log_with, execute)
      else
        log_with.call(format_params(log_params))
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
