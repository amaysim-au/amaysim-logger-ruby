require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/time/zones'

class AmaysimLogger
  module Helpers
    class << self
      def log_timestamp(time = Time.now)
        time = time.in_time_zone('Sydney')
        "#{time} #{time.zone}"
      end

      def exception_hash(e)
        {
          exception: e.class.name,
          exception_msg: e.message,
          exception_backtrace: e.backtrace.join("\n")
        }
      end

      def message_hash(msg)
        if msg.is_a? Hash
          msg
        else
          { msg: msg }
        end
      end
    end
  end
end
