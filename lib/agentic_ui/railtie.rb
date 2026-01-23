# frozen_string_literal: true

module AgenticUi
  # Rails integration for revolutionary agentic CMS
  class Railtie < Rails::Railtie
    # Add AgenticUI helper to ActionView
    initializer "agentic_ui.action_view" do
      ActiveSupport.on_load :action_view do
        include AgenticUi::Helper
      end
    end

    # Load configuration after Rails initializes
    config.after_initialize do
      AgenticUi.load_defaults!
    end

    # Add rake tasks
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |f| load f }
    end
  end

  # Helper module for Rails views
  module Helper
    # Revolutionary ux method that returns the AgenticUI Display singleton
    def ux
      AgenticUi::Display.instance
    end

    # Set agent context for current request
    def set_agent_context(agent_context)
      AgenticUi::AgentContext.current = agent_context
    end

    # Get current agent context
    def agent_context
      AgenticUi::AgentContext.current
    end

    # Render agent-aware CSS layers
    def agentic_css_layers
      return unless AgenticUi.configuration.css_layers_enabled
      
      css = AgenticUi::CssLayers.generate_layered_css(agent_context)
      content_tag(:style, css.html_safe, data: { 'agentic-layers': true })
    end

    # Generate CSS custom properties for current agent
    def agentic_css_variables
      return unless agent_context
      
      css_vars = agent_context.css_variables
      return if css_vars.empty?
      
      style_content = ":root { #{css_vars.map { |k, v| "#{k}: #{v};" }.join(' ')} }"
      content_tag(:style, style_content.html_safe, data: { 'agentic-vars': true })
    end

    # Create agent context from session
    def load_agent_context_from_session
      context = AgenticUi::AgentContext.from_rails_session(session)
      set_agent_context(context) if context
      context
    end

    # Create agent context from agent session model
    def load_agent_context_from_model(agent_session)
      context = AgenticUi::AgentContext.from_agent_session(agent_session)
      set_agent_context(context) if context
      context
    end

    # Wrap content with agent context
    def with_agent_context(context, &block)
      AgenticUi::AgentContext.with_context(context, &block)
    end

    # Check if component is AI controllable
    def ai_controllable?(component_name)
      AgenticUi.configuration.ai_controllable?(component_name)
    end

    # Get AI commands for component
    def ai_commands_for(component_name)
      AgenticUi.configuration.ai_commands(component_name)
    end

    # Generate data attributes for AI control
    def ai_control_data(component_name)
      return {} unless ai_controllable?(component_name)
      
      {
        'ai-controllable' => 'true',
        'ai-commands' => ai_commands_for(component_name).join(','),
        'css-layer' => AgenticUi.configuration.css_layer(component_name)
      }
    end
  end
end