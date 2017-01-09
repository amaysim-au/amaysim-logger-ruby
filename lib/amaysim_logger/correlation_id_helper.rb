require 'securerandom'
require 'active_support/concern'

class AmaysimLogger
  module CorrelationIdHelper
    extend ActiveSupport::Concern

    def correlation_id
      @correlation_id ||= request.headers['CORRELATION-ID'] || new_correlation_id
    end

    private

    def new_correlation_id
      SecureRandom.uuid
    end
  end
end
