class AmaysimLogger
  class EventHandler
    def call(event)
      output = {}
      output.merge!(extract_headers(event))
      output.merge!(extract_exception(event))
      output.merge!(extract_sydney_time(event))
      output.merge!(extract_log_context)
      output
    end

    private

    def extract_headers(event)
      return {} unless event.payload.key? :headers

      headers = event.payload[:headers]
      {
        user_agent: headers['HTTP_USER_AGENT'],
        request_id: headers['action_dispatch.request_id'] || SecureRandom.uuid,
        remote_ip: headers['action_dispatch.remote_ip'].to_s,
        correlation_id: headers['HTTP_CORRELATION_ID'] || SecureRandom.uuid
      }
    end

    def extract_exception(event)
      return {} unless event.payload.key? :exception_object
      AmaysimLogger::Helpers.exception_hash(event.payload[:exception_object])
    end

    def extract_sydney_time(event)
      {
        log_timestamp: AmaysimLogger::Helpers.log_timestamp(event.time)
      }
    end

    def extract_log_context
      return {} if AmaysimLogger.logger.log_context.empty?
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
