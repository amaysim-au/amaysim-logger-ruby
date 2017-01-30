require 'json'
require 'active_support/logger'
require 'request_store'

class AmaysimLogger
  class JSONFormatter < ActiveSupport::Logger::SimpleFormatter
    def call(severity, timestamp, progname, msg)
      output = default_log_hash(severity, timestamp)
      output.merge!(AmaysimLogger::Helpers.message_hash(msg))
      msg = ::JSON.dump(output)
      super
    end

    private

    def default_log_hash(severity, timestamp)
      {
        level: severity,
        log_timestamp: AmaysimLogger::Helpers.log_timestamp(timestamp)
      }
    end
  end

  class Logger < ActiveSupport::Logger
    def initialize(*args)
      super
      @formatter = JSONFormatter.new
    end

    def add(severity, message = nil, progname = nil, &block)
      return true if @logdev.nil? || (severity || UNKNOWN) < level

      message = run_block(severity, message, progname, &block) if block_given?

      super
    ensure
      raise @_exception if @_exception
    end

    def log_context
      RequestStore[:log_context] ||= {}
    end

    def log_context=(context)
      RequestStore[:log_context] = context
    end

    def add_to_log_context(params = {})
      new_params = \
        if params.is_a?(Hash)
          log_context.merge(params)
        else
          { data: params }
        end

      self.log_context = new_params
    end

    private

    # rubocop:disable Metrics/MethodLength
    def run_block(_severity, message = nil, progname = nil)
      output = {}

      begin
        start_time = Time.now
        output[:start_time] = AmaysimLogger::Helpers.log_timestamp(start_time)
        yield
      rescue StandardError => e
        output.merge!(AmaysimLogger::Helpers.exception_hash(e))
        @_exception = e
      ensure
        end_time = Time.now
        output[:end_time] = AmaysimLogger::Helpers.log_timestamp(end_time)
        output[:duration] = (end_time - start_time)
        output
      end

      output.merge!(AmaysimLogger::Helpers.message_hash(message || progname))

      output
    end
  end
end
