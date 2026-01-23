# frozen_string_literal: true

module AgenticUi
  # Revolutionary CSS Layers integration for agentic CMS
  # Manages the 7-layer CSS architecture with agent-aware styling
  #
  # Aligns with agentic-layers.scss canonical layer system (January 2026):
  # foundation → framework → agentic-primitives → components → ai-generated → interactive → utilities
  class CssLayers
    # Define the 7-layer CSS architecture for agentic CMS
    # Must match: app/frontend/stylesheets/agentic-layers.scss
    LAYER_ORDER = %w[
      foundation
      framework
      agentic-primitives
      components
      ai-generated
      interactive
      utilities
    ].freeze

    # Layer priorities (higher number = higher priority)
    LAYER_PRIORITIES = {
      'foundation' => 1,
      'framework' => 2,
      'agentic-primitives' => 3,
      'components' => 4,
      'ai-generated' => 5,
      'interactive' => 6,
      'utilities' => 7
    }.freeze

    # Legacy layer name mappings for backward compatibility
    LEGACY_LAYER_MAPPING = {
      'agentic-layout' => 'agentic-primitives',
      'agentic-components' => 'components',
      'agentic-interactive' => 'interactive',
      'agentic-utilities' => 'utilities'
    }.freeze

    # Generate CSS @layer declaration
    def self.layer_declaration
      "@layer #{LAYER_ORDER.join(', ')};"
    end

    # Get layer for component type
    def self.layer_for_component(component_type)
      config = AgenticUi.configuration.component_config(component_type)
      config["css_layer"] || default_layer_for_component(component_type)
    end

    # Determine default layer based on component type
    # Maps component types to the 7-layer system
    def self.default_layer_for_component(component_type)
      case component_type.to_s
      when 'container', 'grid', 'column', 'row', 'layout', 'section'
        'agentic-primitives'
      when 'button', 'input', 'select', 'textarea', 'link', 'form'
        'interactive'
      when 'widget', 'card', 'meta', 'content', 'header', 'icon', 'image', 'video'
        'components'
      when 'agent', 'ai', 'generated', 'personality', 'theme'
        'ai-generated'
      else
        'components'
      end
    end

    # Normalize layer name (handles legacy names)
    def self.normalize_layer(layer)
      layer_str = layer.to_s
      LEGACY_LAYER_MAPPING[layer_str] || layer_str
    end

    # Generate CSS for all layers with agent context
    def self.generate_layered_css(agent_context = nil)
      css_output = []
      
      # Add layer declaration
      css_output << layer_declaration
      css_output << ""
      
      # Generate CSS for each layer
      LAYER_ORDER.each do |layer|
        layer_css = generate_layer_css(layer, agent_context)
        css_output << layer_css if layer_css
      end
      
      css_output.join("\n")
    end

    # Generate CSS for a specific layer
    # Supports all 7 layers: foundation → framework → agentic-primitives → components → ai-generated → interactive → utilities
    def self.generate_layer_css(layer, agent_context = nil)
      css_rules = []
      normalized_layer = normalize_layer(layer)

      case normalized_layer
      when 'foundation'
        css_rules << generate_foundation_css(agent_context)
      when 'framework'
        css_rules << generate_framework_css(agent_context)
      when 'agentic-primitives'
        css_rules << generate_primitives_css(agent_context)
      when 'components'
        css_rules << generate_components_css(agent_context)
      when 'ai-generated'
        css_rules << generate_ai_generated_css(agent_context)
      when 'interactive'
        css_rules << generate_interactive_css(agent_context)
      when 'utilities'
        css_rules << generate_utilities_css(agent_context)
      end

      return nil if css_rules.compact.empty?

      "@layer #{normalized_layer} {\n#{css_rules.compact.join("\n")}\n}"
    end

    # Generate foundation layer CSS (CSS custom properties)
    def self.generate_foundation_css(agent_context)
      return nil unless agent_context
      
      css_vars = agent_context.css_variables
      return nil if css_vars.empty?
      
      properties = css_vars.map { |property, value| "  #{property}: #{value};" }
      
      ":root {\n#{properties.join("\n")}\n}"
    end

    # Generate framework layer CSS (base component styles)
    def self.generate_framework_css(agent_context)
      # This would integrate with existing framework CSS
      # For now, return basic reset styles
      <<~CSS
        * {
          box-sizing: border-box;
        }
        
        [data-agentic-ui] {
          transition: var(--agentic-transition-duration, 0.2s) ease-in-out;
        }
      CSS
    end

    # Generate agentic-primitives layer CSS (layout primitives, glass, gradients, animations)
    def self.generate_primitives_css(agent_context)
      <<~CSS
        .container {
          max-width: var(--agentic-container-width, 1200px);
          margin: 0 auto;
          padding: var(--agentic-container-padding, 1rem);
        }

        .grid {
          display: grid;
          gap: var(--agentic-grid-gap, 1rem);
          grid-template-columns: var(--agentic-grid-columns, 1fr);
        }

        .column {
          grid-column: var(--agentic-column-span, auto);
        }

        /* Glass morphism primitives */
        .glass {
          background: var(--agentic-glass-background, rgba(255, 255, 255, 0.1));
          backdrop-filter: var(--agentic-glass-blur, blur(10px));
          border: var(--agentic-glass-border, 1px solid rgba(255, 255, 255, 0.2));
        }

        /* Gradient primitives */
        .gradient-primary {
          background: var(--agentic-gradient-primary, linear-gradient(135deg, var(--agent-primary, #2563eb), var(--agent-primary-dark, #1d4ed8)));
        }
      CSS
    end

    # Alias for backward compatibility
    def self.generate_layout_css(agent_context)
      generate_primitives_css(agent_context)
    end

    # Generate components layer CSS
    def self.generate_components_css(agent_context)
      css = []
      
      # Base component styles
      css << <<~CSS
        .widget {
          background: var(--agentic-widget-background, var(--agent-surface, #ffffff));
          border-radius: var(--agentic-widget-radius, var(--agent-border-radius, 6px));
          padding: var(--agentic-widget-padding, var(--agent-spacing, 1rem));
          box-shadow: var(--agentic-widget-shadow, var(--agent-shadow, 0 1px 3px rgba(0,0,0,0.1)));
        }
        
        .card {
          background: var(--agentic-card-background, var(--agent-surface, #ffffff));
          border-radius: var(--agentic-card-radius, var(--agent-border-radius, 8px));
          padding: var(--agentic-card-padding, var(--agent-spacing, 1rem));
          box-shadow: var(--agentic-card-shadow, var(--agent-shadow, 0 1px 3px rgba(0,0,0,0.1)));
          transition: transform var(--agentic-transition-duration, 0.2s) ease;
        }
        
        .card:hover {
          transform: translateY(var(--agentic-card-hover-lift, -2px));
        }
        
        .content {
          color: var(--agentic-content-color, var(--agent-text, #1f2937));
          line-height: var(--agentic-content-line-height, 1.6);
        }
        
        .meta {
          color: var(--agentic-meta-color, var(--agent-muted, #6b7280));
          font-size: var(--agentic-meta-size, 0.875rem);
        }
        
        .header {
          color: var(--agentic-header-color, var(--agent-text, #1f2937));
          font-weight: var(--agentic-header-weight, 600);
          margin-bottom: var(--agentic-header-margin, 0.5rem);
        }
        
        .icon {
          width: var(--agentic-icon-size, 1em);
          height: var(--agentic-icon-size, 1em);
          display: inline-block;
        }
      CSS
      
      # Agent-aware styles
      if agent_context&.personality
        css << generate_personality_css(agent_context.personality)
      end
      
      css.join("\n\n")
    end

    # Generate ai-generated layer CSS (agent personality & dynamic theming)
    # This layer contains styles that are dynamically generated based on agent personality
    def self.generate_ai_generated_css(agent_context)
      css = []

      # Base AI-generated styles
      css << <<~CSS
        /* AI-generated dynamic styles */
        [data-agent-generated] {
          transition: all var(--agentic-transition-duration, 0.2s) ease;
        }

        [data-agent-theme] {
          --agent-theme-applied: true;
        }

        /* Dynamic color application from agent personality */
        .agent-primary-bg {
          background-color: var(--agent-primary, #2563eb);
        }

        .agent-accent-bg {
          background-color: var(--agent-accent, #8b5cf6);
        }

        .agent-surface-bg {
          background-color: var(--agent-surface, #ffffff);
        }
      CSS

      # Personality-specific AI styles
      if agent_context&.personality
        css << generate_personality_css(agent_context.personality)
      end

      css.compact.join("\n\n")
    end

    # Generate interactive layer CSS
    def self.generate_interactive_css(agent_context)
      <<~CSS
        .btn {
          background: var(--agentic-button-background, var(--agent-primary, #2563eb));
          color: var(--agentic-button-color, #ffffff);
          border: var(--agentic-button-border, none);
          border-radius: var(--agentic-button-radius, var(--agent-border-radius, 6px));
          padding: var(--agentic-button-padding, var(--agent-spacing-sm, 0.5rem) var(--agent-spacing, 1rem));
          font-weight: var(--agentic-button-weight, 500);
          cursor: pointer;
          transition: all var(--agentic-transition-duration, 0.2s) ease;
        }
        
        .btn:hover {
          background: var(--agentic-button-hover-background, var(--agent-primary-dark, #1d4ed8));
          transform: var(--agentic-button-hover-transform, translateY(-1px));
        }
        
        .btn:active {
          transform: var(--agentic-button-active-transform, translateY(0));
        }
        
        .field {
          background: var(--agentic-input-background, #ffffff);
          border: var(--agentic-input-border, 1px solid var(--agent-border, #d1d5db));
          border-radius: var(--agentic-input-radius, var(--agent-border-radius-sm, 4px));
          padding: var(--agentic-input-padding, var(--agent-spacing-sm, 0.5rem));
          font-size: var(--agentic-input-size, 1rem);
          transition: border-color var(--agentic-transition-duration, 0.2s) ease;
        }
        
        .field:focus {
          outline: none;
          border-color: var(--agentic-input-focus-border, var(--agent-primary, #2563eb));
          box-shadow: 0 0 0 3px var(--agentic-input-focus-shadow, rgba(37, 99, 235, 0.1));
        }
      CSS
    end

    # Generate utilities layer CSS
    def self.generate_utilities_css(agent_context)
      <<~CSS
        /* Agent-aware utilities */
        [data-agent-personality] {
          transition: all var(--agentic-transition-duration, 0.2s) ease;
        }
        
        [data-ai-controllable="true"] {
          position: relative;
        }
        
        [data-ai-controllable="true"]::after {
          content: "";
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          pointer-events: none;
          border: var(--agentic-ai-indicator-border, 1px dashed transparent);
          border-radius: inherit;
          transition: border-color var(--agentic-transition-duration, 0.2s) ease;
        }
        
        [data-ai-controllable="true"]:hover::after {
          border-color: var(--agentic-ai-indicator-color, var(--agent-primary, #2563eb));
        }
        
        /* Responsive utilities */
        @media (max-width: 768px) {
          .container {
            padding: var(--agentic-container-padding-mobile, 0.5rem);
          }
          
          .grid {
            grid-template-columns: 1fr;
          }
        }
      CSS
    end

    # Generate personality-specific CSS
    def self.generate_personality_css(personality)
      case personality.to_s.downcase
      when 'professional'
        <<~CSS
          [data-agent-personality="professional"] {
            --agentic-border-radius: 4px;
            --agentic-shadow-intensity: 0.08;
            --agentic-transition-duration: 0.15s;
          }
        CSS
      when 'casual'
        <<~CSS
          [data-agent-personality="casual"] {
            --agentic-border-radius: 12px;
            --agentic-shadow-intensity: 0.12;
            --agentic-transition-duration: 0.3s;
          }
        CSS
      when 'technical'
        <<~CSS
          [data-agent-personality="technical"] {
            --agentic-border-radius: 2px;
            --agentic-shadow-intensity: 0.05;
            --agentic-transition-duration: 0.1s;
            --agentic-font-family: 'Monaco', 'Consolas', monospace;
          }
        CSS
      else
        ""
      end
    end

    # Check if layer is valid (handles legacy names via normalization)
    def self.valid_layer?(layer)
      normalized = normalize_layer(layer)
      LAYER_ORDER.include?(normalized)
    end

    # Get layer priority (handles legacy names via normalization)
    def self.layer_priority(layer)
      normalized = normalize_layer(layer)
      LAYER_PRIORITIES[normalized] || 0
    end
  end
end