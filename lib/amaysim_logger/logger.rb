require 'json'
require 'active_support/logger'
require 'request_store'

class AmaysimLogger
  class JSONFormatter < ActiveSupport::Logger::SimpleFormatter
    def call(severity, timestamp, progname, msg)
      # If the message is already JSON-looking, then bail out.
      # FIXME: this will return false-positives for inspected ruby hashes i.e.
      # {"foo"=>"bar"}
      if msg && msg[0] == '{' && msg[1] == '"'
        super
        return
      end

      output = {
        level: severity,
        log_timestamp: AmaysimLogger::Helpers.log_timestamp(timestamp)
      }

      if msg.is_a? Hash
        output.merge!(msg)
      else
        output[:msg] = msg
      end

      msg = ::JSON.dump(output)
      super
    end
  end

  class Logger < ActiveSupport::Logger
    def initialize(*args)
      super
      @formatter = JSONFormatter.new
    end

    def add(severity, message = nil, progname = nil, &block)
      return true if @logdev.nil? || (severity || UNKNOWN) < level

      if block_given?
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

        msg = message || progname
        if msg.is_a? Hash
          output.merge!(msg)
        else
          output[:msg] = msg
        end

        message = output
      end

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
        if log_context.is_a?(Hash)
          log_context.merge(params)
        else
          { data: params }
        end

      self.log_context = new_params
    end
  end
end
