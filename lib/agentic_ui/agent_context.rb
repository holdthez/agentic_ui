# frozen_string_literal: true

module AgenticUi
  # Revolutionary AgentContext for agent-aware UI components
  # Enables dynamic theming based on AI agent personalities and preferences
  class AgentContext
    attr_reader :session_id, :personality, :theme_preferences, :ui_preferences

    def initialize(session_id: nil, personality: nil, theme_preferences: {}, ui_preferences: {})
      @session_id = session_id
      @personality = personality
      @theme_preferences = theme_preferences || {}
      @ui_preferences = ui_preferences || {}
    end

    # Thread-safe current context storage
    def self.current
      Thread.current[:agentic_ui_context]
    end

    def self.current=(context)
      Thread.current[:agentic_ui_context] = context
    end

    # Set context for the duration of a block
    def self.with_context(context)
      old_context = current
      self.current = context
      yield
    ensure
      self.current = old_context
    end

    # Create context from agent session (integrates with your AgentSession model)
    def self.from_agent_session(agent_session)
      return nil unless agent_session

      theme_prefs = {}
      ui_prefs = {}

      # Extract preferences from agent session
      if agent_session.respond_to?(:theme_preferences)
        theme_prefs = agent_session.theme_preferences || {}
      end

      if agent_session.respond_to?(:ui_preferences)
        ui_prefs = agent_session.ui_preferences || {}
      end

      # Get personality
      personality = if agent_session.respond_to?(:personality)
                     agent_session.personality
                   elsif agent_session.respond_to?(:agent) && agent_session.agent&.personality
                     agent_session.agent.personality
                   else
                     'default'
                   end

      new(
        session_id: agent_session.session_token || agent_session.id,
        personality: personality,
        theme_preferences: theme_prefs,
        ui_preferences: ui_prefs
      )
    end

    # Create context from Rails session
    def self.from_rails_session(session)
      return nil unless session

      new(
        session_id: session[:agent_session_id],
        personality: session[:agent_personality] || 'default',
        theme_preferences: session[:agent_theme_preferences] || {},
        ui_preferences: session[:agent_ui_preferences] || {}
      )
    end

    # Get CSS variables for current agent context
    def css_variables
      variables = {}
      
      # Add theme preference variables
      @theme_preferences.each do |key, value|
        css_key = "--agent-#{key.to_s.dasherize}"
        variables[css_key] = value
      end
      
      # Add personality-specific variables
      if @personality && @personality != 'default'
        variables["--agent-personality"] = @personality
        variables["--agent-personality-#{@personality}"] = "active"
      end
      
      variables
    end

    # Get data attributes for HTML elements
    def data_attributes
      attrs = {}
      
      attrs["agent-session"] = @session_id if @session_id
      attrs["agent-personality"] = @personality if @personality && @personality != 'default'
      
      # Add condensed theme preferences
      if @theme_preferences.any?
        attrs["agent-theme"] = @theme_preferences.map { |k, v| "#{k}:#{v}" }.join(";")
      end
      
      attrs
    end

    # Check if context has specific preference
    def has_preference?(key)
      @theme_preferences.key?(key.to_s) || @theme_preferences.key?(key.to_sym)
    end

    # Get preference value
    def preference(key)
      @theme_preferences[key.to_s] || @theme_preferences[key.to_sym]
    end

    # Get UI preference value
    def ui_preference(key)
      @ui_preferences[key.to_s] || @ui_preferences[key.to_sym]
    end

    # Check if agent prefers dark mode
    def dark_mode?
      preference('color_scheme') == 'dark' || preference('theme') == 'dark'
    end

    # Check if agent has high contrast preference
    def high_contrast?
      preference('contrast') == 'high' || ui_preference('accessibility_high_contrast') == true
    end

    # Check if agent prefers reduced motion
    def reduced_motion?
      ui_preference('prefers_reduced_motion') == true
    end

    # Get component-specific styling
    def component_style(component_type)
      component_prefs = @ui_preferences[component_type.to_s] || {}
      style_declarations = []
      
      # Add CSS variables for component
      css_variables.each do |property, value|
        style_declarations << "#{property}: #{value}"
      end
      
      # Add component-specific preferences
      component_prefs.each do |property, value|
        css_property = "--#{component_type}-#{property.to_s.dasherize}"
        style_declarations << "#{css_property}: #{value}"
      end
      
      style_declarations.join("; ") unless style_declarations.empty?
    end

    # Merge with another context (useful for inheritance)
    def merge(other_context)
      return self unless other_context.is_a?(AgentContext)
      
      AgentContext.new(
        session_id: other_context.session_id || @session_id,
        personality: other_context.personality || @personality,
        theme_preferences: @theme_preferences.merge(other_context.theme_preferences),
        ui_preferences: @ui_preferences.merge(other_context.ui_preferences)
      )
    end

    # Convert to hash for serialization
    def to_h
      {
        session_id: @session_id,
        personality: @personality,
        theme_preferences: @theme_preferences,
        ui_preferences: @ui_preferences
      }
    end

    # Create from hash
    def self.from_hash(hash)
      return nil unless hash.is_a?(Hash)
      
      new(
        session_id: hash[:session_id] || hash['session_id'],
        personality: hash[:personality] || hash['personality'],
        theme_preferences: hash[:theme_preferences] || hash['theme_preferences'] || {},
        ui_preferences: hash[:ui_preferences] || hash['ui_preferences'] || {}
      )
    end
  end
end