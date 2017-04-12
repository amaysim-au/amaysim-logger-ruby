require 'securerandom'
require 'active_support/concern'

class AmaysimLogger
  module CorrelationIdHelper
    extend ActiveSupport::Concern

    def correlation_id
      @correlation_id ||= request.headers['CORRELATION-ID'] || request.uuid
    end
  end
end
