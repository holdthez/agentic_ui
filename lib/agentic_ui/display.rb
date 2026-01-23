# frozen_string_literal: true

require 'singleton'
require_relative 'rapid_ui_compat'

# Revolutionary AgenticUI with full RapidUI backward compatibility
module Ui
  # Drop-in replacement for RapidUI's Display class
  # Now with AI agent awareness and revolutionary YAML-driven architecture
  class Display < ActionView::Base
    include Singleton
    include AgenticUi::RapidUiCompat  # Full RapidUI backward compatibility

    def initialize
      create_component_methods!
    end

    # Reinitialize when configuration changes
    def self.reinitialize!
      instance.send(:create_component_methods!)
    end

    private

    def create_component_methods!
      # Clear existing component methods
      clear_component_methods!
      
      # Create methods for each UI component
      AgenticUi.configuration.ui_hash["ui"].each do |component_name, _config|
        create_component_method(component_name)
      end
    end

    def create_component_method(component_name)
      # Define method that handles multiple argument patterns for agentic CMS compatibility
      define_singleton_method component_name.to_s do |*args, **kwargs, &block|
        # Get component configuration
        config = AgenticUi.configuration.component_config(component_name)

        # Handle multiple argument patterns (the fix that started this journey!)
        merged_args = process_arguments(args, kwargs, component_name)

        # REVOLUTIONARY: Full RapidUI backward compatibility processing
        # This enables all rapid_ui features: responsive grids, Stimulus shortcuts, etc.
        merged_args = process_rapid_ui_args!(merged_args, config)

        # Enhance with agent context if component is agent-aware
        if config["agent_aware"] && AgenticUi.configuration.agent_context_enabled
          merged_args = enhance_with_agent_context(merged_args, component_name)
        end

        # Add CSS layer information
        if AgenticUi.configuration.css_layers_enabled && config["css_layer"]
          merged_args[:data] ||= {}
          merged_args[:data]["css-layer"] = config["css_layer"]
        end

        # Add AI controllable marker
        if config["ai_controllable"]
          merged_args[:data] ||= {}
          merged_args[:data]["ai-controllable"] = "true"
          merged_args[:data]["ai-commands"] = config["ai_commands"]&.join(",")
        end

        # Create the wrapper component
        AgenticUi::WrapperComponent.new(component_name.to_sym, **merged_args, &block)
      end
    end

    def process_arguments(args, kwargs, component_name)
      if args.any?
        first_arg = args.first
        second_arg = args[1]

        # Ensure second_arg is a Hash (guard against String/nil)
        second_arg = {} unless second_arg.is_a?(Hash)

        if first_arg.is_a?(String)
          # Template pattern: ux.widget('discussions', data: {...})
          # Convert to: ux.widget(class: 'discussions', data: {...})
          merged_args = { class: first_arg }.merge(second_arg).merge(kwargs)
        elsif first_arg.is_a?(Hash)
          # Hash pattern: ux.widget({class: 'discussions'}, data: {...})
          merged_args = first_arg.merge(second_arg).merge(kwargs)
        else
          # Fallback for any other first argument type
          merged_args = { class: first_arg.to_s }.merge(second_arg).merge(kwargs)
        end
      else
        # Pure kwargs pattern: ux.widget(class: 'discussions', data: {...})
        merged_args = kwargs.is_a?(Hash) ? kwargs : {}
      end

      # RapidUI compatibility: allow single string argument (the original bug fix!)
      merged_args = { class: merged_args } if merged_args.is_a?(String)

      # Final safety: ensure we always return a Hash
      merged_args = {} unless merged_args.is_a?(Hash)

      merged_args
    end

    def enhance_with_agent_context(args, component_name)
      # Get current agent context
      agent_context = AgenticUi::AgentContext.current
      return args unless agent_context
      
      # Add agent-specific styling
      args[:data] ||= {}
      args[:data]["agent-session"] = agent_context.session_id if agent_context.session_id
      args[:data]["agent-personality"] = agent_context.personality if agent_context.personality
      
      # Apply agent theme preferences
      if agent_context.theme_preferences.any?
        args[:style] ||= ""
        agent_context.theme_preferences.each do |property, value|
          css_var = "--agent-#{property.to_s.dasherize}"
          args[:style] += "#{css_var}: #{value}; "
        end
      end
      
      args
    end

    def clear_component_methods!
      # Get list of component methods to remove
      component_methods = AgenticUi.configuration.ui_hash["ui"].keys.map(&:to_s)
      
      # Remove existing component methods
      component_methods.each do |method_name|
        singleton_class.remove_method(method_name) if respond_to?(method_name)
      rescue NameError
        # Method doesn't exist, ignore
      end
    end
  end
end