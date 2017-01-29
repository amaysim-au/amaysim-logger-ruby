class AmaysimLogger
  class EventHandler
    def call(event)
      output = {}
      output.merge!(extract_headers(event)) if event.payload.key? :headers

      output.merge!(extract_exeption(event)) if event.payload.key? :exception

      output.merge!(extract_sydney_time(event))

      unless AmaysimLogger.logger.log_context.empty?
        output.merge!(extract_log_context)
      end
      output
    end

    private

    def extract_headers(event)
      {
        user_agent: event.payload[:headers]['HTTP_USER_AGENT'],
        request_id: event.payload[:headers]['action_dispatch.request_id'],
        remote_id: event.payload[:headers]['action_dispatch.remote_ip'].to_s
      }
    end

    def extract_exeption(event)
      {
        exception: event.payload[:exception][0],
        exception_msg: event.payload[:exception][1],
        exception_backtrace: event.payload[:exception_object].backtrace.join("\n")
      }
    end

    def extract_sydney_time(event)
      {
        log_timestamp: AmaysimLogger::Helpers.log_timestamp(event.time)
      }
    end

    def extract_log_context
      if AmaysimLogger.logger.log_context.is_a? Hash
        AmaysimLogger.logger.log_context
      else
        {
          log_context: AmaysimLogger.logger.log_context
        }
      end
    end
  end
end
