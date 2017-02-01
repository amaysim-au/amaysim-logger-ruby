require 'amaysim_logger/rails_controller_helper'
require 'amaysim_logger/rails_ext/rack/logger'

# Parts of this file are modified from [lograge](https://github.com/roidrage/lograge)
# The MIT License (MIT)
# Copyright (c) 2016 Mathias Meyer

class AmaysimLogger
  class Railtie < Rails::Railtie
    config.amaysim_logger = ActiveSupport::OrderedOptions.new
    config.amaysim_logger.disable_action_view_logs = true
    config.amaysim_logger.disable_action_controller_logs = true
    config.amaysim_logger.disable_active_record_logs = true
    config.amaysim_logger.disable_active_job_logs = true

    config.action_view.logger = AmaysimLogger if defined? ActionView
    config.action_controller.logger = AmaysimLogger if defined? ActionController
    config.active_record.logger = AmaysimLogger if defined? ActiveRecord
    config.active_job.logger = AmaysimLogger if defined? ActiveJob

    config.after_initialize do |_app|
      ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
        case subscriber.class.to_s
        when 'ActionView::LogSubscriber'
          if config.amaysim_logger.disable_action_view_logs
            unsubscribe(:action_view, subscriber)
          end
        when 'ActionController::LogSubscriber'
          if config.amaysim_logger.disable_action_controller_logs
            unsubscribe(:action_controller, subscriber)
          end
        when 'ActiveRecord::LogSubscriber'
          if config.amaysim_logger.disable_active_record_logs
            unsubscribe(:active_record, subscriber)
          end
        when 'ActiveJob::LogSubscriber'
          if config.amaysim_logger.disable_active_job_logs
            unsubscribe(:active_job, subscriber)
          end
        end
      end
    end

    class << self
      private

      def unsubscribe(component, sub)
        events = sub.public_methods(false).reject do |method|
          method.to_s == 'call'
        end
        events.each do |event|
          unsubscribe_component_event(component, event, sub)
        end
      end

      def unsubscribe_component_event(component, event, sub)
        ActiveSupport::Notifications
          .notifier.listeners_for("#{event}.#{component}").each do |listener|
          if listener.instance_variable_get('@delegate') == sub
            ActiveSupport::Notifications.unsubscribe listener
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:action_controller) do
  include AmaysimLogger::RailsControllerHelper
end
