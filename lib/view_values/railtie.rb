# frozen_string_literal: true

begin
  require 'rails/railtie'
rescue LoadError
  # Rails not available; Railtie won't be loaded.
end

if defined?(Rails::Railtie)
  module ViewValues
    class Railtie < ::Rails::Railtie
      initializer 'view_values.include_provider' do
        ActiveSupport.on_load(:action_controller) do
          include ViewValues::Provider
        end
      end
    end
  end
end
