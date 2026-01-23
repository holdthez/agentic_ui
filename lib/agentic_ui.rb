# frozen_string_literal: true

require_relative "agentic_ui/version"
require_relative "agentic_ui/configuration"
require_relative "agentic_ui/display"
require_relative "agentic_ui/wrapper_component"
require_relative "agentic_ui/agent_context"
require_relative "agentic_ui/css_layers"

module AgenticUi
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ComponentError < Error; end

  # Configuration accessor
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  # Reset configuration (useful for testing)
  def self.reset_configuration!
    @configuration = nil
  end

  # Load default UI components if Rails is available
  def self.load_defaults!
    return unless defined?(Rails)

    config_path = Rails.root.join('config/agentic_ui.yml')
    if File.exist?(config_path)
      configuration.load_from_file(config_path)
    else
      configuration.load_defaults!
    end
  end

  # Boot AgenticUI - initialize Display singleton with components
  def self.boot
    # Force initialization of Ui::Display singleton
    # This creates all component methods from YAML config
    Ui::Display.instance
    true
  end
end

# Auto-load in Rails environment
if defined?(Rails)
  require_relative "agentic_ui/railtie"
end
