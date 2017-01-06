require 'active_support/logger'
require 'request_store'

class AmaysimLogger
  def self.info(msg:, params: {}, execute: nil)
    AmaysimLogger.new.log(msg: msg, params: params,
                          log_with: ->(log_msg) { logger.info(log_msg) },
                          execute: execute)
  end

  def self.debug(msg:, params: {}, execute: nil)
    AmaysimLogger.new.log(msg: msg, params: params,
                          log_with: ->(log_msg) { logger.debug(log_msg) },
                          execute: execute)
  end

  def self.warn(msg:, params: {}, execute: nil)
    AmaysimLogger.new.log(msg: msg, params: params,
                          log_with: ->(log_msg) { logger.warn(log_msg) },
                          execute: execute)
  end

  def self.error(msg:, params: {}, execute: nil)
    AmaysimLogger.new.log(msg: msg, params: params,
                          log_with: ->(log_msg) { logger.error(log_msg) },
                          execute: execute)
  end

  def self.append_to_log(params = {})
    if RequestStore[:log_append].is_a?(Hash)
      RequestStore[:log_append] = RequestStore[:log_append].merge(params)
    else
      RequestStore[:log_append] = params
    end
  end

  def self.logger
    @logger ||= ActiveSupport::Logger.new(STDOUT)
  end

  def log(msg:, params: {}, log_with:, execute: nil)
    log_params = create_log_params(msg, params)
    if execute
      return log_with_duration(
        log_params: log_params,
        log_with: log_with,
        execute: execute
      )
    end
    log_with.call(format_params(log_params))
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

  # rubocop:disable Matrics/MethodLength
  def log_with_duration(log_params:, log_with:, execute:)
    start_time = Time.now
    log_params[:start_time] = log_timestamp(start_time)
    return execute.call
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
    params.map { |k, v| "#{k}=#{v}" }.join(', ')
  end
end
