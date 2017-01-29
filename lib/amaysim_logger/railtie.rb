require 'rails/railtie'
require 'lograge'

class AmaysimLogger
  class Railtie < Rails::Railtie
    config.logger = AmaysimLogger.logger
    config.action_controller.logger = config.logger if defined? ActionController
    config.active_record.logger = config.logger if defined? ActiveRecord
    config.lograge.logger = config.logger
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.enabled = true
    config.lograge.custom_options = AmaysimLogger::EventHandler.new
  end
end

ActiveSupport.on_load(:action_controller) do
  include AmaysimLogger::RailsControllerHelper
end
