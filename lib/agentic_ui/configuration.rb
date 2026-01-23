# frozen_string_literal: true

require 'yaml'

module AgenticUi
  # Revolutionary YAML-driven configuration for agentic CMS
  # Enables AI agents to dynamically control UI components
  class Configuration
    attr_accessor :ui_hash, :css_layers_enabled, :agent_context_enabled, :theme_integration, :stimulus_integration
    attr_reader :ui_file

    def initialize
      @ui_hash = { "ui" => {} }
      @css_layers_enabled = true
      @agent_context_enabled = true
      @theme_integration = true
      @stimulus_integration = true
      @ui_file = nil
    end

    # Set UI configuration file path and load it
    def ui_file=(file_path)
      @ui_file = file_path
      load_from_file(file_path) if file_path
    end

    # Load configuration from YAML file
    def load_from_file(file_path)
      return unless File.exist?(file_path)
      
      config = YAML.safe_load(File.read(file_path), permitted_classes: [Symbol])
      @ui_hash = config || { "ui" => {} }
    rescue => e
      raise ConfigurationError, "Failed to load configuration from #{file_path}: #{e.message}"
    end

    # Load configuration with RapidUI backward compatibility
    def load_defaults!
      return if @ui_hash && @ui_hash["ui"] && @ui_hash["ui"].any?
      
      # Check for existing config files (backward compatibility)
      if defined?(Rails)
        agentic_config_path = Rails.root.join('config', 'agentic_ui.yml')
        rapid_config_path = Rails.root.join('config', 'ui.yml')
        
        if File.exist?(agentic_config_path)
          load_from_file(agentic_config_path)
          return
        elsif File.exist?(rapid_config_path)
          # Load existing RapidUI config and enhance it
          load_from_file(rapid_config_path)
          enhance_rapid_ui_config!
          return
        end
      end
      
      # Use built-in revolutionary defaults
      @ui_hash = {
        "ui" => {
          # Core Layout Components
          "container" => {
            "tag" => "div",
            "css_class" => "container",
            "ai_controllable" => true,
            "ai_commands" => ["theme", "layout", "responsive"],
            "css_layer" => "agentic-layout",
            "unified_theme_vars" => ["--container-width", "--container-padding"]
          },
          
          "grid" => {
            "tag" => "div", 
            "css_class" => "grid",
            "ai_controllable" => true,
            "ai_commands" => ["layout", "columns", "gap"],
            "css_layer" => "agentic-layout"
          },
          
          "column" => {
            "tag" => "div",
            "css_class" => "column",
            "ai_controllable" => true,
            "ai_commands" => ["width", "responsive", "order"],
            "css_layer" => "agentic-layout"
          },

          # Revolutionary Agentic Components
          "widget" => {
            "tag" => "div",
            "css_class" => "widget",
            "ai_controllable" => true,
            "ai_commands" => ["theme", "layout", "animate", "personality"],
            "css_layer" => "agentic-components",
            "agent_aware" => true,
            "stimulus_controller" => "agentic-widget"
          },

          "card" => {
            "tag" => "div",
            "css_class" => "card", 
            "ai_controllable" => true,
            "ai_commands" => ["theme", "layout", "animate", "elevation"],
            "css_layer" => "agentic-components",
            "agent_aware" => true,
            "stimulus_controller" => "enhanced-card"
          },

          "button" => {
            "tag" => "button",
            "css_class" => "btn",
            "ai_controllable" => true,
            "ai_commands" => ["theme", "style", "animate", "resize", "personality"],
            "css_layer" => "agentic-interactive", 
            "agent_aware" => true,
            "stimulus_controller" => "enhanced-button"
          },

          # Content Components
          "content" => {
            "tag" => "div",
            "css_class" => "content",
            "ai_controllable" => true,
            "ai_commands" => ["typography", "spacing", "theme"],
            "css_layer" => "agentic-content"
          },

          "meta" => {
            "tag" => "div",
            "css_class" => "meta",
            "ai_controllable" => true,
            "ai_commands" => ["theme", "typography"],
            "css_layer" => "agentic-content"
          },

          "description" => {
            "tag" => "div", 
            "css_class" => "description",
            "ai_controllable" => true,
            "ai_commands" => ["typography", "theme"],
            "css_layer" => "agentic-content"
          },

          "header" => {
            "tag" => "div",
            "css_class" => "header",
            "ai_controllable" => true,
            "ai_commands" => ["typography", "theme", "hierarchy"],
            "css_layer" => "agentic-content"
          },

          # Interactive Components
          "input" => {
            "tag" => "input",
            "css_class" => "field",
            "ai_controllable" => true,
            "ai_commands" => ["theme", "validate", "format", "personality"],
            "css_layer" => "agentic-interactive",
            "agent_aware" => true,
            "stimulus_controller" => "enhanced-input"
          },

          "overlay" => {
            "tag" => "div",
            "css_class" => "overlay",
            "ai_controllable" => true,
            "ai_commands" => ["theme", "animate", "backdrop"],
            "css_layer" => "agentic-overlay"
          },

          "icon" => {
            "tag" => "i",
            "css_class" => "icon",
            "ai_controllable" => true,
            "ai_commands" => ["theme", "size", "animate"],
            "css_layer" => "agentic-components"
          },

          "item" => {
            "tag" => "div",
            "css_class" => "item", 
            "ai_controllable" => true,
            "ai_commands" => ["theme", "layout", "interactive"],
            "css_layer" => "agentic-components"
          }
        }
      }
    end

    # Get component configuration
    def component_config(name)
      @ui_hash.dig("ui", name.to_s) || {}
    end

    # Check if component is AI controllable
    def ai_controllable?(name)
      component_config(name)["ai_controllable"] == true
    end

    # Get AI commands for component
    def ai_commands(name)
      component_config(name)["ai_commands"] || []
    end

    # Get CSS layer for component
    def css_layer(name)
      component_config(name)["css_layer"] || "agentic-components"
    end

    # Check if component is agent aware
    def agent_aware?(name)
      component_config(name)["agent_aware"] == true
    end

    # Get all AI controllable components
    def ai_controllable_components
      @ui_hash["ui"].select { |_, config| config["ai_controllable"] == true }.keys
    end

    # Enhance RapidUI config with AgenticUI features
    def enhance_rapid_ui_config!
      return unless @ui_hash["ui"]
      
      # Add AI-controllable features to key components
      enhancements = {
        "widget" => {
          "ai_controllable" => true,
          "ai_commands" => ["theme", "layout", "animate", "personality"],
          "css_layer" => "agentic-components",
          "agent_aware" => true,
          "stimulus_controller" => "agentic-widget"
        },
        "card" => {
          "ai_controllable" => true,
          "ai_commands" => ["theme", "layout", "animate", "elevation"],
          "css_layer" => "agentic-components",
          "agent_aware" => true,
          "stimulus_controller" => "enhanced-card"
        },
        "button" => {
          "ai_controllable" => true,
          "ai_commands" => ["theme", "style", "animate", "resize"],
          "css_layer" => "agentic-interactive",
          "stimulus_controller" => "enhanced-button"
        },
        "input" => {
          "ai_controllable" => true,
          "ai_commands" => ["theme", "validate", "format"],
          "css_layer" => "agentic-interactive",
          "stimulus_controller" => "enhanced-input"
        }
      }
      
      # Apply enhancements to existing components
      enhancements.each do |component_name, enhancement|
        if @ui_hash["ui"][component_name]
          @ui_hash["ui"][component_name].merge!(enhancement)
        end
      end
    end

    # Validate configuration
    def validate!
      errors = []
      
      return true unless @ui_hash["ui"] # Skip validation if no UI config
      
      @ui_hash["ui"].each do |name, config|
        errors << "Component #{name} missing tag" unless config["tag"]
        errors << "Component #{name} missing css_class" unless config["css_class"]
        
        if config["ai_controllable"] && !config["ai_commands"]
          errors << "AI controllable component #{name} missing ai_commands"
        end
      end
      
      raise ConfigurationError, "Configuration errors: #{errors.join(', ')}" if errors.any?
      true
    end
  end
end