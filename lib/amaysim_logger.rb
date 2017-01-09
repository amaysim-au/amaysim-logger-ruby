require 'active_support/logger'
require 'request_store'

class AmaysimLogger
  class << self
    [:info, :debug, :warn, :error].each do |level|
      define_method(level) do |msg:, params: {}, execute: nil|
        log(
          msg: msg,
          params: params,
          log_with: ->(log_msg) { logger.send(level, log_msg) },
          execute: execute
        )
      end
    end

    def append_to_log(params = {})
      if RequestStore[:log_append].is_a?(Hash)
        RequestStore[:log_append] = RequestStore[:log_append].merge(params)
      else
        RequestStore[:log_append] = params
      end
    end

    def logger
      @logger ||= ActiveSupport::Logger.new(STDOUT)
    end

    def log(msg:, params: {}, log_with:, execute: nil)
      log_params = create_log_params(msg, params)
      if execute
        log_with_duration(log_params, log_with, execute)
      else
        log_with.call(format_params(log_params))
      end
    end

    private

    def log_timestamp(time = Time.now)
      "#{time} #{time.zone}"
    end

    def create_log_params(msg, params)
      timestamped_message = { msg: msg, log_timestamp: log_timestamp }
      timestamped_message.merge(request_params).merge(params)
    end

    def request_params
      RequestStore[:log_append] || {}
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
