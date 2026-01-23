# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'agentic_ui'
require 'minitest/autorun'

# Configure AgenticUI for testing
AgenticUi.configure do |config|
  config.ui_file = File.expand_path('../config/agentic_ui.yml', __dir__)
  config.css_layers_enabled = true
  config.agent_context_enabled = true
  config.theme_integration = true
  config.stimulus_integration = true
end
