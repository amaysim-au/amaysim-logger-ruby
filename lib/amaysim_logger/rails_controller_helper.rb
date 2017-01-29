class AmaysimLogger
  module RailsControllerHelper
    def add_to_log_context(params = {})
      AmaysimLogger.logger.add_to_log_context(params)
    end
  end
end
