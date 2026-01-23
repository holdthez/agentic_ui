# frozen_string_literal: true

module AgenticUi
  # Revolutionary WrapperComponent for agentic CMS
  # Integrates with UnifiedTheme CSS variables and agent personalities
  class WrapperComponent
    attr_reader :component_type, :config, :args, :block, :agent

    # Keys that are consumed by render_data_content methods (hero, statistics, grid, etc.)
    # These should NOT be output as HTML attributes on the outer container
    DATA_DRIVEN_KEYS = %i[
      headline subtitle description title content text
      statistics stats items cards entries rows columns
      cta_text cta_url cta_primary cta_secondary button_text button_link
      image_url background_image video_url poster fallback_image
      section_title grid_title show_icons features benefits
      primary_cta_text primary_cta_url secondary_cta_text secondary_cta_url
      min_height text_alignment overlay_opacity duration_ms animate_on_scroll
      faqs plans sections headers gap
    ].freeze

    def initialize(component_type, agent: nil, **args, &block)
      @component_type = component_type
      @agent = agent
      @config = AgenticUi.configuration.component_config(component_type)
      @args = args
      @block = block

      validate_component!
      process_css_classes!
      process_variant!  # Phase 6: Apply variant modifiers and variables
      process_css_overrides!  # Design DNA: Apply css_overrides as inline styles
      integrate_unified_theme!
      apply_agent_preferences! if @agent  # Phase 2A: Apply learned preferences
    end

    # Render component to HTML
    def render_in(view_context, &block)
      # Store the block if passed to render_in (Rails standard pattern)
      # Use ||= to preserve block from initialize (critical for nested components)
      @block ||= block if block_given?
      
      # Handle special cases for Rails routing and form helpers
      if component_type.to_s == 'link' && @args[:to]
        render_link_component(view_context)
      elsif component_type.to_s == 'form'
        render_form_component(view_context)
      else
        render_standard_component(view_context)
      end
    end

    # Make it work with Rails rendering system
    def to_s
      ''
    end

    # Check if component is AI controllable
    def ai_controllable?
      @config["ai_controllable"] == true
    end

    # Get available AI commands
    def ai_commands
      @config["ai_commands"] || []
    end

    # Get CSS layer
    def css_layer
      @config["css_layer"] || "agentic-components"
    end

    # Check if agent aware
    def agent_aware?
      @config["agent_aware"] == true
    end

    private

    def validate_component!
      raise ComponentError, "Unknown component type: #{component_type}" if @config.empty?
      raise ComponentError, "Component #{component_type} missing tag configuration" unless @config["tag"]
    end

    def process_css_classes!
      # Combine base CSS class with additional classes (from YAML config AND rapid_ui processing)
      base_class = @config["css_class"] || ""
      additional_classes = @args[:class] || ""

      # CRITICAL: Preserve rapid_ui processed classes (responsive grid, ui class, etc.)
      # These have already been processed by display.rb's process_rapid_ui_args!
      @processed_classes = [base_class, additional_classes].reject(&:empty?).join(" ").strip
      @processed_classes = nil if @processed_classes.empty?

      # Remove :class from args since we'll handle it separately
      @args.delete(:class)
    end

    # Phase 6: Process variant parameter for component variations
    # Supports: css_modifier, css_variables, stimulus_controller, render_method
    def process_variant!
      # Get variant name from args (symbol or string key)
      variant_name = @args.delete(:variant) || @args.delete('variant')
      return unless variant_name.present?

      # Look up variant config from component definition
      variants = @config["variants"]
      return unless variants.is_a?(Hash)

      variant_config = variants[variant_name.to_s]
      unless variant_config
        Rails.logger.warn("[AgenticUI] Unknown variant '#{variant_name}' for #{component_type}, available: #{variants.keys.join(', ')}")
        return
      end

      # Store variant config for later use (render_method, stimulus_controller)
      @variant_config = variant_config

      # Apply CSS modifier class (e.g., hero-wrapper--bold)
      if variant_config["css_modifier"].present?
        @processed_classes = [@processed_classes, variant_config["css_modifier"]].compact.join(" ").strip
      end

      # Apply CSS custom properties via inline style
      if variant_config["css_variables"].is_a?(Hash)
        css_vars = variant_config["css_variables"].map { |k, v| "#{k}: #{v}" }.join("; ")
        existing_style = @args[:style] || ""
        @args[:style] = [existing_style, css_vars].reject(&:empty?).join("; ")
      end

      # Store variant data attribute for CSS targeting
      @args[:data] ||= {}
      @args[:data]["variant"] = variant_name.to_s
    end

    # Design DNA: Process css_overrides from section config
    # Converts { "hero-background" => "#0d9488" } to inline CSS variables
    def process_css_overrides!
      css_overrides = @args.delete(:css_overrides) || @args.delete('css_overrides')
      return unless css_overrides.is_a?(Hash) && css_overrides.any?

      # Convert css_overrides to CSS custom properties
      # Keys without -- prefix get it added automatically
      css_vars = css_overrides.map do |key, value|
        var_name = key.to_s.start_with?('--') ? key : "--#{key}"
        "#{var_name}: #{value}"
      end.join("; ")

      # Merge with existing style attribute
      existing_style = @args[:style] || ""
      @args[:style] = [existing_style, css_vars].reject(&:empty?).join("; ")
    end

    def integrate_unified_theme!
      return unless AgenticUi.configuration.theme_integration

      # Add CSS custom properties for UnifiedTheme integration
      # CRITICAL: Ensure :data is always a Hash (fixes stringify_keys error)
      @args[:data] = {} unless @args[:data].is_a?(Hash)
      
      # Add component type for CSS targeting
      @args[:data]["component"] = component_type.to_s
      
      # Add CSS layer information for proper cascade
      @args[:data]["css-layer"] = css_layer if AgenticUi.configuration.css_layers_enabled
      
      # Add UnifiedTheme CSS variables if defined
      unified_theme_vars = @config["unified_theme_vars"]
      if unified_theme_vars.is_a?(Array)
        @args[:data]["theme-vars"] = unified_theme_vars.join(",")
      end
    end

    def render_standard_component(view_context)
      # Allow runtime tag override via args (e.g., tag: 'a' renders as <a> instead of <div>)
      tag_name = @args.delete(:tag) || @args.delete('tag') || @config["tag"]

      # Build attributes hash
      attributes = build_attributes

      # CRITICAL: For hero components, add background image as CSS variable
      # This must happen AFTER build_attributes but BEFORE content_tag
      if hero_component?
        bg_image = @args[:background_image] || @args['background_image'] || @args[:image_url] || @args['image_url'] || @args[:fallback_image] || @args['fallback_image']
        if bg_image.present?
          style_parts = []
          style_parts << "--hero-bg-image: url('#{bg_image}')"
          style_parts << "--hero-overlay: linear-gradient(to bottom, rgba(0,0,0,0.4) 0%, rgba(0,0,0,0.7) 100%)"
          existing_style = attributes[:style] || ''
          attributes[:style] = [existing_style, style_parts.join('; ')].reject(&:blank?).join('; ')
        end
      end

      # Extract text content if provided
      text_content = @args.delete(:text) || @args.delete('text')

      # Render with or without block content
      if @block
        view_context.content_tag(tag_name, **attributes) do
          view_context.capture(&@block)
        end
      elsif data_driven_component?
        # Render data-driven content (statistics, cards, items, etc.)
        view_context.content_tag(tag_name, **attributes) do
          render_data_content(view_context)
        end
      elsif text_content.present?
        # Render with text content from text: parameter
        view_context.content_tag(tag_name, text_content, **attributes)
      else
        # Self-closing tags
        if self_closing_tag?(tag_name)
          view_context.tag(tag_name, **attributes)
        else
          view_context.content_tag(tag_name, '', **attributes)
        end
      end
    end

    def render_link_component(view_context)
      # Handle Rails link_to helper integration
      url = @args.delete(:to)
      attributes = build_attributes
      
      if @block
        view_context.link_to(url, **attributes, &@block)
      else
        view_context.link_to(@args[:text] || '', url, **attributes)
      end
    end

    def render_form_component(view_context)
      # Handle Rails form helpers integration
      attributes = build_attributes
      
      if @block
        view_context.form_with(**@args.merge(local: true), **attributes, &@block)
      else
        view_context.form_with(**@args.merge(local: true), **attributes)
      end
    end

    def build_attributes
      attributes = @args.dup

      # CRITICAL: Remove data-driven content keys from HTML attributes
      # These keys are consumed by render_data_content methods, not output as HTML attributes
      DATA_DRIVEN_KEYS.each do |key|
        attributes.delete(key)
        attributes.delete(key.to_s)
      end

      # CRITICAL: Ensure :data is always a Hash (fixes stringify_keys error)
      # Rails content_tag calls stringify_keys on the attributes hash
      attributes[:data] = {} unless attributes[:data].is_a?(Hash)

      # Extract Stimulus-specific attributes and convert to data-* format
      # These should NOT be rendered as raw HTML attributes
      stimulus_action = attributes.delete(:action) || attributes.delete('action')
      stimulus_controller_arg = attributes.delete(:controller) || attributes.delete('controller')

      # Add CSS classes
      attributes[:class] = @processed_classes if @processed_classes

      # Add component-specific attributes
      if @config["type"]
        attributes[:type] = @config["type"]
      end

      # Determine which stimulus controller to use
      # Phase 6: Variant stimulus_controller takes precedence over component controller
      # Also check for controller passed as arg (runtime override)
      stimulus_controller = if stimulus_controller_arg.present?
                              stimulus_controller_arg
                            elsif @variant_config && @variant_config["stimulus_controller"].present?
                              @variant_config["stimulus_controller"]
                            else
                              @config["stimulus_controller"]
                            end

      # Add Stimulus controller if configured (from arg, variant, or component config)
      if stimulus_controller.present?
        attributes[:data] ||= {}
        existing_controller = attributes[:data][:controller] || attributes[:data]["controller"]
        if existing_controller
          attributes[:data][:controller] = "#{existing_controller} #{stimulus_controller}"
        else
          attributes[:data][:controller] = stimulus_controller
        end
      end

      # Add Stimulus action if provided (converts action: to data-action)
      if stimulus_action.present?
        attributes[:data] ||= {}
        existing_action = attributes[:data][:action] || attributes[:data]["action"]
        if existing_action
          attributes[:data][:action] = "#{existing_action} #{stimulus_action}"
        else
          attributes[:data][:action] = stimulus_action
        end
      end

      attributes
    end

    def self_closing_tag?(tag_name)
      %w[area base br col embed hr img input link meta param source track wbr].include?(tag_name)
    end

    # Check if component has data arrays that need rendering
    # Supports: statistics, cards, items, list items, grid items, hero content, tables (rows)
    # Also honors data_driven: true from YAML config (core/ui.yml)
    def data_driven_component?
      return true if hero_component?
      return true if @args[:statistics].is_a?(Array) && @args[:statistics].any?
      return true if @args[:cards].is_a?(Array) && @args[:cards].any?
      return true if @args[:items].is_a?(Array) && @args[:items].any?
      return true if @args[:entries].is_a?(Array) && @args[:entries].any?
      # Table components use :rows
      return true if @args[:rows].is_a?(Array) && @args[:rows].any?
      # Honor data_driven: true from YAML config (enables render_method dispatch)
      return true if @config["data_driven"] == true
      false
    end

    # Check if this is a hero-type component
    def hero_component?
      component_name = component_type.to_s.downcase

      # Explicit hero types
      hero_types = %w[hero_wrapper hero_section hero_video_background ux.hero_wrapper ux.hero_section]
      return true if hero_types.include?(component_name)
      return true if component_name.include?('hero')

      # CRITICAL: Components with render_method defined use their own rendering logic
      # EXCEPTION: render_method: 'hero' still uses hero rendering
      render_method = @config["render_method"]
      if render_method.present? && render_method != 'hero'
        return false  # Non-hero render_method handles its own headline (as H2/H3)
      end

      # Exclude simple component types that should NEVER have hero content injected
      # These components may have title/headline for accessibility but should not render hero HTML
      non_hero_types = %w[
        icon button item link menu dropdown divider header label badge image avatar
        input checkbox radio toggle segment container grid column row
        timeline timeline_vertical timeline_display team_grid cards statistics
        accordion tabs table list featured_grid certifications_grid values_grid
        testimonials pricing faq navigation footer cta cta_section split_layout
        bento_grid stats_counter kpi_dashboard logo_cloud feature_grid
        testimonial_grid contact_cards comparison_table pricing_cards
      ]
      return false if non_hero_types.include?(component_name)

      # ux.* primitives that are not explicitly hero types should not render as hero
      # (hero types already caught above by include?('hero') check)
      if component_name.start_with?('ux.') && !component_name.include?('hero')
        return false
      end

      # Check for hero content fields (only for components not explicitly excluded)
      has_hero_content = @args[:headline].present? || @args['headline'].present? ||
                         @args[:title].present? || @args['title'].present? ||
                         @args[:subtitle].present? || @args['subtitle'].present?
      has_hero_content
    end

    # Render data-driven content based on component type
    # Creates semantic HTML for statistics, cards, grids, heroes, etc.
    # Phase 2: Now honors render_method from YAML config (single source of truth)
    # Phase 6: Variant render_method takes precedence over component render_method
    def render_data_content(view_context)
      # Phase 6: Check variant-specific render_method FIRST (highest priority)
      if @variant_config && @variant_config["render_method"].present?
        variant_render_method = @variant_config["render_method"]
        method_name = "render_#{variant_render_method}_content"
        if respond_to?(method_name, true)
          return send(method_name, view_context)
        else
          Rails.logger.warn("[AgenticUI] Unknown variant render_method '#{variant_render_method}' for #{component_type}, falling back")
        end
      end

      # Phase 2 FIX: Check render_method from YAML config SECOND (single source of truth)
      # This ensures core/ui.yml render_method definitions are honored
      render_method = @config["render_method"]

      if render_method.present?
        method_name = "render_#{render_method}_content"
        if respond_to?(method_name, true)
          return send(method_name, view_context)
        else
          Rails.logger.warn("[AgenticUI] Unknown render_method '#{render_method}' for #{component_type}, falling back to detection")
        end
      end

      # Fallback: Check for hero components (can match multiple patterns)
      return render_hero_content(view_context) if hero_component?

      # Fallback: Match by component_type name
      case component_type.to_s
      when 'statistics'
        render_statistics_content(view_context)
      when 'cards'
        render_cards_content(view_context)
      when 'grid', 'list'
        render_grid_content(view_context)
      else
        # Generic data rendering for other components
        render_generic_data_content(view_context)
      end
    end

    # Render hero section with proper HTML structure for CSS styling
    # Outputs: .hero-content > .hero-headline + .hero-subtitle + .hero-cta-group
    # OPTIMIZED: Returns content_tag directly (no redundant safe_join wrapper)
    def render_hero_content(view_context)
      # Extract hero content from args (support both symbol and string keys)
      headline = @args[:headline] || @args['headline'] || @args[:title] || @args['title']
      subtitle = @args[:subtitle] || @args['subtitle'] || @args[:description] || @args['description']
      cta_text = @args[:cta_text] || @args['cta_text'] || @args[:button_text] || @args['button_text']
      cta_url = @args[:cta_url] || @args['cta_url'] || @args[:button_link] || @args['button_link']
      secondary_cta_text = @args[:secondary_cta_text] || @args['secondary_cta_text']
      secondary_cta_url = @args[:secondary_cta_url] || @args['secondary_cta_url']
      bg_image = @args[:background_image] || @args['background_image'] || @args[:image_url] || @args['image_url']

      # Build CSS variables for background (applied to outer container via @args)
      style_parts = []
      style_parts << "--hero-bg-image: url('#{bg_image}')" if bg_image.present?
      style_parts << "--hero-overlay: linear-gradient(to bottom, rgba(0,0,0,0.3) 0%, rgba(0,0,0,0.6) 100%)" if bg_image.present?

      # Apply styles to outer container
      if style_parts.any?
        @args[:style] = [(@args[:style] || ''), style_parts.join('; ')].reject(&:blank?).join('; ')
      end

      # Return single content_tag directly (no intermediate array)
      view_context.content_tag(:div, class: 'hero-content') do
        hero_inner = []

        # Headline with animation attribute
        if headline.present?
          hero_inner << view_context.content_tag(:h1, headline,
            class: 'hero-headline',
            data: { animate: 'fade-up' })
        end

        # Subtitle
        if subtitle.present?
          hero_inner << view_context.content_tag(:p, subtitle,
            class: 'hero-subtitle',
            data: { animate: 'fade-up' })
        end

        # CTA button group
        if cta_text.present? && cta_url.present?
          hero_inner << view_context.content_tag(:div, class: 'hero-cta-group', data: { animate: 'fade-up' }) do
            cta_buttons = []
            cta_buttons << view_context.link_to(cta_text, cta_url, class: 'hero-cta primary')
            if secondary_cta_text.present? && secondary_cta_url.present?
              cta_buttons << view_context.link_to(secondary_cta_text, secondary_cta_url, class: 'hero-cta secondary')
            end
            view_context.safe_join(cta_buttons)
          end
        end

        view_context.safe_join(hero_inner)
      end
    end

    # Phase 6: Render hero with background video
    # For variant: "video" - includes video element behind hero content
    def render_hero_video_content(view_context)
      video_url = @args[:video_url] || @args['video_url']
      poster = @args[:poster] || @args['poster'] || @args[:background_image] || @args['background_image']

      video_html = if video_url.present?
                     view_context.content_tag(:div, class: 'hero-video-container') do
                       view_context.tag(:video,
                                        src: video_url,
                                        poster: poster,
                                        autoplay: true,
                                        muted: true,
                                        loop: true,
                                        playsinline: true,
                                        class: 'hero-video')
                     end
                   else
                     ''.html_safe
                   end

      # Render standard hero content on top
      hero_content = render_hero_content(view_context)

      view_context.safe_join([video_html, hero_content])
    end

    # Phase 6: Render hero with split layout (content + media)
    # For variant: "split" - two columns: text on one side, image/media on other
    def render_hero_split_content(view_context)
      headline = @args[:headline] || @args['headline'] || @args[:title] || @args['title']
      subtitle = @args[:subtitle] || @args['subtitle'] || @args[:description] || @args['description']
      cta_text = @args[:cta_text] || @args['cta_text']
      cta_url = @args[:cta_url] || @args['cta_url']
      secondary_cta_text = @args[:secondary_cta_text] || @args['secondary_cta_text']
      secondary_cta_url = @args[:secondary_cta_url] || @args['secondary_cta_url']
      media_url = @args[:media_url] || @args['media_url'] || @args[:image_url] || @args['image_url'] || @args[:background_image] || @args['background_image']
      media_alt = @args[:media_alt] || @args['media_alt'] || headline || ''
      reverse = @args[:reverse] || @args['reverse']

      layout_class = reverse ? 'hero-split-layout hero-split-layout--reverse' : 'hero-split-layout'

      view_context.content_tag(:div, class: layout_class) do
        parts = []

        # Content column
        parts << view_context.content_tag(:div, class: 'hero-split-content') do
          content_parts = []
          content_parts << view_context.content_tag(:h1, headline, class: 'hero-headline', data: { animate: 'fade-up' }) if headline.present?
          content_parts << view_context.content_tag(:p, subtitle, class: 'hero-subtitle', data: { animate: 'fade-up' }) if subtitle.present?

          if cta_text.present? && cta_url.present?
            content_parts << view_context.content_tag(:div, class: 'hero-cta-group', data: { animate: 'fade-up' }) do
              cta_buttons = []
              cta_buttons << view_context.link_to(cta_text, cta_url, class: 'hero-cta primary')
              cta_buttons << view_context.link_to(secondary_cta_text, secondary_cta_url, class: 'hero-cta secondary') if secondary_cta_text.present? && secondary_cta_url.present?
              view_context.safe_join(cta_buttons)
            end
          end

          view_context.safe_join(content_parts)
        end

        # Media column
        parts << view_context.content_tag(:div, class: 'hero-split-media', data: { animate: 'fade-left' }) do
          if media_url.present?
            view_context.image_tag(media_url, alt: media_alt, class: 'hero-split-image')
          else
            ''.html_safe
          end
        end

        view_context.safe_join(parts)
      end
    end

    # Render statistics as formatted HTML
    # OPTIMIZED: Only use safe_join when section_title present
    def render_statistics_content(view_context)
      statistics = @args[:statistics] || @args['statistics'] || []
      return ''.html_safe if statistics.empty?

      section_title = @args[:section_title] || @args['section_title']
      layout_class = (@args[:layout] || @args['layout']) == 'vertical' ? 'stats-vertical' : 'stats-horizontal'

      # Build statistics items
      stats_html = statistics.map do |stat|
        stat = stat.symbolize_keys if stat.is_a?(Hash)
        render_statistic_item(view_context, stat)
      end

      # Build stats grid
      stats_grid = view_context.content_tag(:div, class: "stats-grid #{layout_class}") do
        view_context.safe_join(stats_html)
      end

      # Only use safe_join when section title is present
      if section_title.present?
        title_tag = view_context.content_tag(:h2, section_title, class: 'stats-title')
        view_context.safe_join([title_tag, stats_grid])
      else
        stats_grid
      end
    end

    def render_statistic_item(view_context, stat)
      view_context.content_tag(:div, class: 'stat-item') do
        inner = []
        if stat[:icon].present?
          icon_class = stat[:icon].include?('-') ? "i-#{stat[:icon]}" : "i-ph-#{stat[:icon]}"
          inner << view_context.content_tag(:div, '', class: "stat-icon #{icon_class}",
            style: stat[:color].present? ? "color: #{stat[:color]}" : nil)
        end
        inner << view_context.content_tag(:div, stat[:value], class: 'stat-value')
        inner << view_context.content_tag(:div, stat[:label], class: 'stat-label')
        view_context.safe_join(inner)
      end
    end

    # Render cards as formatted HTML
    # OPTIMIZED: Only use safe_join when section_title or section_subtitle present
    def render_cards_content(view_context)
      cards = @args[:cards] || @args['cards'] || []
      return ''.html_safe if cards.empty?

      section_title = @args[:section_title] || @args['section_title']
      section_subtitle = @args[:section_subtitle] || @args['section_subtitle']
      columns = @args[:columns] || @args['columns'] || 3

      # Build cards items
      cards_html = cards.map do |card|
        card = card.symbolize_keys if card.is_a?(Hash)
        render_card_item(view_context, card)
      end

      # Build cards grid
      cards_grid = view_context.content_tag(:div, class: "cards-grid cards-cols-#{[columns.to_i, 4].min}") do
        view_context.safe_join(cards_html)
      end

      # Only use safe_join when header elements are present
      has_header = section_title.present? || section_subtitle.present?
      if has_header
        header_elements = []
        header_elements << view_context.content_tag(:h2, section_title, class: 'cards-title') if section_title.present?
        header_elements << view_context.content_tag(:p, section_subtitle, class: 'cards-subtitle') if section_subtitle.present?
        view_context.safe_join(header_elements + [cards_grid])
      else
        cards_grid
      end
    end

    def render_card_item(view_context, card)
      view_context.content_tag(:div, class: 'card-item') do
        inner = []
        if card[:image].present?
          inner << view_context.content_tag(:div, class: 'card-image') do
            view_context.tag(:img, src: card[:image], alt: card[:title] || '', loading: 'lazy')
          end
        end
        inner << view_context.content_tag(:div, class: 'card-content') do
          card_inner = []
          card_inner << view_context.content_tag(:h3, card[:title] || card[:header], class: 'card-title') if card[:title] || card[:header]
          card_inner << view_context.content_tag(:p, card[:description], class: 'card-desc') if card[:description]
          card_inner << view_context.content_tag(:div, card[:meta], class: 'card-meta') if card[:meta]
          if card[:link].present?
            card_inner << view_context.link_to('Learn more', card[:link], class: 'card-link')
          end
          view_context.safe_join(card_inner)
        end
        view_context.safe_join(inner)
      end
    end

    # Render grid/list items as formatted HTML
    # OPTIMIZED: Only use safe_join when section_title present
    def render_grid_content(view_context)
      items = @args[:items] || @args['items'] || []
      return ''.html_safe if items.empty?

      section_title = @args[:section_title] || @args['section_title']
      columns = @args[:columns] || @args['columns'] || 3

      # Build grid items
      items_html = items.map do |item|
        if item.is_a?(Hash)
          item = item.symbolize_keys
          render_grid_item(view_context, item)
        else
          view_context.content_tag(:div, item.to_s, class: 'grid-item')
        end
      end

      # Build items grid
      items_grid = view_context.content_tag(:div, class: "items-grid grid-cols-#{[columns.to_i, 4].min}") do
        view_context.safe_join(items_html)
      end

      # Only use safe_join when section title is present
      if section_title.present?
        title_tag = view_context.content_tag(:h2, section_title, class: 'grid-title')
        view_context.safe_join([title_tag, items_grid])
      else
        items_grid
      end
    end

    def render_grid_item(view_context, item)
      view_context.content_tag(:div, class: 'grid-item') do
        inner = []
        if item[:icon].present?
          icon_class = item[:icon].include?('-') ? "i-#{item[:icon]}" : "i-ph-#{item[:icon]}"
          inner << view_context.content_tag(:div, '', class: "grid-icon #{icon_class}")
        end
        inner << view_context.content_tag(:h4, item[:title] || item[:header], class: 'grid-item-title') if item[:title] || item[:header]
        inner << view_context.content_tag(:p, item[:description] || item[:content], class: 'grid-item-desc') if item[:description] || item[:content]
        view_context.safe_join(inner)
      end
    end

    # Phase 2: Additional render methods from core/ui.yml
    # These ensure render_method: 'X' in YAML is honored

    # Render accordion component
    def render_accordion_content(view_context)
      items = @args[:items] || @args['items'] || @args[:sections] || @args['sections'] || []
      return ''.html_safe if items.empty?

      view_context.content_tag(:div, class: 'accordion', data: { controller: 'accordion' }) do
        items_html = items.map.with_index do |item, idx|
          item = item.symbolize_keys if item.is_a?(Hash)
          view_context.content_tag(:div, class: 'accordion-item', data: { accordion_target: 'item' }) do
            header = view_context.content_tag(:button, item[:title] || item[:header] || "Item #{idx + 1}",
              class: 'accordion-header',
              data: { action: 'accordion#toggle' })
            content = view_context.content_tag(:div, class: 'accordion-content') do
              view_context.content_tag(:p, item[:content] || item[:description] || '')
            end
            view_context.safe_join([header, content])
          end
        end
        view_context.safe_join(items_html)
      end
    end

    # Render tabs component
    def render_tabs_content(view_context)
      tabs = @args[:tabs] || @args['tabs'] || @args[:items] || @args['items'] || []
      return ''.html_safe if tabs.empty?

      view_context.content_tag(:div, class: 'tabs', data: { controller: 'tabs' }) do
        # Tab headers
        headers = view_context.content_tag(:div, class: 'tabs-header', role: 'tablist') do
          tabs.map.with_index do |tab, idx|
            tab = tab.symbolize_keys if tab.is_a?(Hash)
            view_context.content_tag(:button, tab[:label] || tab[:title] || "Tab #{idx + 1}",
              class: "tab-button#{idx == 0 ? ' active' : ''}",
              role: 'tab',
              data: { action: 'tabs#select', tabs_target: 'tab' })
          end.then { |buttons| view_context.safe_join(buttons) }
        end

        # Tab panels
        panels = tabs.map.with_index do |tab, idx|
          tab = tab.symbolize_keys if tab.is_a?(Hash)
          view_context.content_tag(:div, class: "tab-panel#{idx == 0 ? ' active' : ''}",
            role: 'tabpanel',
            data: { tabs_target: 'panel' }) do
            view_context.content_tag(:p, tab[:content] || tab[:description] || '')
          end
        end.then { |p| view_context.safe_join(p) }

        view_context.safe_join([headers, panels])
      end
    end

    # Render table component
    def render_table_content(view_context)
      rows = @args[:rows] || @args['rows'] || @args[:data] || @args['data'] || []
      headers = @args[:headers] || @args['headers'] || @args[:columns] || @args['columns'] || []
      return ''.html_safe if rows.empty?

      view_context.content_tag(:div, class: 'table-wrapper') do
        view_context.content_tag(:table, class: 'data-table') do
          table_parts = []

          # Header row
          if headers.any?
            table_parts << view_context.content_tag(:thead) do
              view_context.content_tag(:tr) do
                headers.map do |h|
                  h = h.is_a?(Hash) ? (h[:label] || h[:title] || h.values.first) : h
                  view_context.content_tag(:th, h)
                end.then { |cells| view_context.safe_join(cells) }
              end
            end
          end

          # Body rows
          table_parts << view_context.content_tag(:tbody) do
            rows.map do |row|
              view_context.content_tag(:tr) do
                cells = row.is_a?(Hash) ? row.values : (row.is_a?(Array) ? row : [row])
                cells.map { |cell| view_context.content_tag(:td, cell.to_s) }
                     .then { |c| view_context.safe_join(c) }
              end
            end.then { |r| view_context.safe_join(r) }
          end

          view_context.safe_join(table_parts)
        end
      end
    end

    # Render timeline component
    def render_timeline_content(view_context)
      events = @args[:events] || @args['events'] || @args[:items] || @args['items'] || []
      return ''.html_safe if events.empty?

      view_context.content_tag(:div, class: 'timeline') do
        events.map do |event|
          event = event.symbolize_keys if event.is_a?(Hash)
          view_context.content_tag(:div, class: 'timeline-item') do
            inner = []
            inner << view_context.content_tag(:div, event[:date] || event[:time] || '', class: 'timeline-date')
            inner << view_context.content_tag(:div, class: 'timeline-content') do
              content = []
              content << view_context.content_tag(:h4, event[:title] || event[:header], class: 'timeline-title') if event[:title] || event[:header]
              content << view_context.content_tag(:p, event[:description] || event[:content], class: 'timeline-desc') if event[:description] || event[:content]
              view_context.safe_join(content)
            end
            view_context.safe_join(inner)
          end
        end.then { |items| view_context.safe_join(items) }
      end
    end

    # Render split layout component (two-column)
    def render_split_content(view_context)
      left = @args[:left] || @args['left'] || @args[:content] || @args['content']
      right = @args[:right] || @args['right'] || @args[:image] || @args['image']
      reversed = @args[:reversed] || @args['reversed']

      view_context.content_tag(:div, class: "split-layout#{reversed ? ' reversed' : ''}") do
        left_col = view_context.content_tag(:div, class: 'split-content') do
          if left.is_a?(Hash)
            left = left.symbolize_keys
            inner = []
            inner << view_context.content_tag(:h2, left[:headline] || left[:title], class: 'split-headline') if left[:headline] || left[:title]
            inner << view_context.content_tag(:p, left[:description] || left[:text], class: 'split-desc') if left[:description] || left[:text]
            view_context.safe_join(inner)
          else
            view_context.content_tag(:p, left.to_s)
          end
        end

        right_col = view_context.content_tag(:div, class: 'split-media') do
          if right.is_a?(String) && right.match?(/\.(jpg|jpeg|png|gif|webp|svg)/i)
            view_context.tag(:img, src: right, alt: '', loading: 'lazy', class: 'split-image')
          else
            view_context.content_tag(:p, right.to_s)
          end
        end

        view_context.safe_join([left_col, right_col])
      end
    end

    # Render sidebar layout component
    def render_sidebar_content(view_context)
      main = @args[:main] || @args['main'] || @args[:content] || @args['content'] || ''
      sidebar = @args[:sidebar] || @args['sidebar'] || @args[:aside] || @args['aside'] || ''
      position = @args[:sidebar_position] || @args['sidebar_position'] || 'right'

      view_context.content_tag(:div, class: "sidebar-layout sidebar-#{position}") do
        main_col = view_context.content_tag(:main, main.to_s.html_safe, class: 'sidebar-main')
        aside_col = view_context.content_tag(:aside, sidebar.to_s.html_safe, class: 'sidebar-aside')
        view_context.safe_join(position == 'left' ? [aside_col, main_col] : [main_col, aside_col])
      end
    end

    # Render modal component (triggered by JS)
    def render_modal_content(view_context)
      title = @args[:title] || @args['title'] || ''
      content = @args[:content] || @args['content'] || @args[:body] || @args['body'] || ''

      view_context.content_tag(:div, class: 'modal', data: { controller: 'modal' }) do
        view_context.content_tag(:div, class: 'modal-backdrop', data: { action: 'click->modal#close' }) do
          view_context.content_tag(:div, class: 'modal-dialog', role: 'dialog') do
            inner = []
            inner << view_context.content_tag(:header, class: 'modal-header') do
              header_content = []
              header_content << view_context.content_tag(:h2, title, class: 'modal-title') if title.present?
              header_content << view_context.content_tag(:button, '×', class: 'modal-close', data: { action: 'modal#close' })
              view_context.safe_join(header_content)
            end
            inner << view_context.content_tag(:div, content.to_s.html_safe, class: 'modal-body')
            view_context.safe_join(inner)
          end
        end
      end
    end

    # Render article component
    def render_article_content(view_context)
      title = @args[:title] || @args['title'] || @args[:headline] || @args['headline']
      author = @args[:author] || @args['author']
      date = @args[:date] || @args['date'] || @args[:published_at] || @args['published_at']
      content = @args[:content] || @args['content'] || @args[:body] || @args['body'] || ''
      image = @args[:image] || @args['image'] || @args[:featured_image] || @args['featured_image']

      view_context.content_tag(:article, class: 'article') do
        parts = []

        # Featured image
        if image.present?
          parts << view_context.content_tag(:figure, class: 'article-image') do
            view_context.tag(:img, src: image, alt: title || '', loading: 'lazy')
          end
        end

        # Header
        parts << view_context.content_tag(:header, class: 'article-header') do
          header_parts = []
          header_parts << view_context.content_tag(:h1, title, class: 'article-title') if title.present?
          if author.present? || date.present?
            header_parts << view_context.content_tag(:div, class: 'article-meta') do
              meta = []
              meta << view_context.content_tag(:span, author, class: 'article-author') if author.present?
              meta << view_context.content_tag(:time, date, class: 'article-date') if date.present?
              view_context.safe_join(meta, ' · ')
            end
          end
          view_context.safe_join(header_parts)
        end

        # Content
        parts << view_context.content_tag(:div, content.to_s.html_safe, class: 'article-content')

        view_context.safe_join(parts)
      end
    end

    # Generic fallback for other data-driven components
    def render_generic_data_content(view_context)
      # Try to render any array data found
      data = @args[:items] || @args[:entries] || @args[:statistics] || @args[:cards] || []
      return ''.html_safe if data.empty?

      items_html = data.map do |item|
        if item.is_a?(Hash)
          item = item.symbolize_keys
          view_context.content_tag(:div, class: 'data-item') do
            inner = []
            inner << view_context.content_tag(:span, item[:value] || item[:title], class: 'item-primary') if item[:value] || item[:title]
            inner << view_context.content_tag(:span, item[:label] || item[:description], class: 'item-secondary') if item[:label] || item[:description]
            view_context.safe_join(inner)
          end
        else
          view_context.content_tag(:div, item.to_s, class: 'data-item')
        end
      end

      view_context.safe_join(items_html)
    end

    # Phase 2A: Agent Learning Integration
    # Apply learned preferences from ComponentRenderingBridgeService
    def apply_agent_preferences!
      return unless defined?(ComponentRenderingBridgeService)
      return unless agent_aware?  # Only apply to agent-aware components

      # Validate tenant security
      tenant_id = extract_tenant_id
      if tenant_id && @agent.respond_to?(:tenant_id) && @agent.tenant_id != tenant_id
        Rails.logger.warn("[AgenticUI Security] Cross-tenant agent rejected: agent #{@agent.id} for tenant #{tenant_id}")
        return  # Reject cross-tenant agent
      end

      # Initialize bridge service with agent context
      bridge_service = ComponentRenderingBridgeService.new(
        agent: @agent,
        tenant_id: tenant_id
      )

      # Get merged preferences (base config + learned + A/B test)
      result = bridge_service.call(
        component_type: @component_type.to_s,
        base_config: @config.deep_dup,
        component_data: @args
      )

      # Phase 2A: Extract and apply learned CSS variables (from learned OR A/B test)
      if result[:preferences_applied][:learned] || result[:preferences_applied][:ab_test]
        apply_css_variables(result)
      end

      # Phase 2B: Extract and apply HTML attributes (from learned OR A/B test)
      if result[:preferences_applied][:learned] || result[:preferences_applied][:ab_test]
        apply_html_attributes(result)
      end

      # Add agent session tracking
      @args[:data] ||= {}
      @args[:data]['agent-session'] = @agent.id.to_s if @agent.respond_to?(:id) && @agent.id.present?
      @args[:data]['agent-aware'] = 'true'

    rescue => e
      Rails.logger.warn("[AgenticUI] Agent preference application failed: #{e.message}")
      Rails.logger.debug(e.backtrace.join("\n"))
      # Graceful fallback - continue without learned preferences
    end

    # Extract tenant ID from Current context or agent
    def extract_tenant_id
      # Try Current.tenant_id first (set by controller)
      if defined?(Current) && Current.respond_to?(:tenant_id) && Current.tenant_id.present?
        return Current.tenant_id
      end

      # Fall back to agent's tenant_id
      if @agent.respond_to?(:tenant_id)
        return @agent.tenant_id
      end

      nil
    end

    # Apply CSS variables from learned preferences
    def apply_css_variables(bridge_result)
      return unless bridge_result.is_a?(Hash)

      # Get theme variables from UnifiedThemeVariableService integration
      theme_vars = bridge_result.dig(:rendered, :theme_variables) || {}

      # Filter for component-specific variables
      component_vars = theme_vars.select do |key, _value|
        key.to_s.start_with?("--#{@component_type}")
      end

      # Apply to inline style
      if component_vars.any?
        @args[:style] ||= ''
        component_vars.each do |var, value|
          @args[:style] += "#{var}: #{value}; "
        end
        @args[:style].strip!
      end
    end

    # Phase 2B: Apply HTML attributes from learned preferences
    # Handles layout, animation, accessibility, responsive, and interaction attributes
    def apply_html_attributes(bridge_result)
      return unless bridge_result.is_a?(Hash)

      # Get HTML attributes from bridge result
      html_attrs = bridge_result.dig(:rendered, :html_attributes) || {}
      return if html_attrs.empty?

      # Category 1: Layout Attributes
      apply_layout_attributes(html_attrs[:layout]) if html_attrs[:layout]

      # Category 2: Animation Attributes
      apply_animation_attributes(html_attrs[:animation]) if html_attrs[:animation]

      # Category 3: Accessibility Attributes
      apply_accessibility_attributes(html_attrs[:accessibility]) if html_attrs[:accessibility]

      # Category 4: Responsive Attributes
      apply_responsive_attributes(html_attrs[:responsive]) if html_attrs[:responsive]

      # Category 5: Interaction Attributes
      apply_interaction_attributes(html_attrs[:interaction]) if html_attrs[:interaction]
    end

    # Apply layout-related attributes (flexbox, grid, positioning)
    def apply_layout_attributes(layout_attrs)
      return unless layout_attrs.is_a?(Hash)

      # Data attributes for CSS targeting
      @args[:data] ||= {}
      @args[:data]['layout'] = layout_attrs[:display] if layout_attrs[:display]
      @args[:data]['flex-direction'] = layout_attrs[:flex_direction] if layout_attrs[:flex_direction]
      @args[:data]['justify'] = layout_attrs[:justify_content] if layout_attrs[:justify_content]
      @args[:data]['align'] = layout_attrs[:align_items] if layout_attrs[:align_items]
      @args[:data]['grid-cols'] = layout_attrs[:grid_columns] if layout_attrs[:grid_columns]
      @args[:data]['gap'] = layout_attrs[:gap] if layout_attrs[:gap]
    end

    # Apply animation-related attributes
    def apply_animation_attributes(animation_attrs)
      return unless animation_attrs.is_a?(Hash)

      @args[:data] ||= {}
      @args[:data]['animation'] = animation_attrs[:type] if animation_attrs[:type]
      @args[:data]['animation-duration'] = animation_attrs[:duration] if animation_attrs[:duration]
      @args[:data]['animation-delay'] = animation_attrs[:delay] if animation_attrs[:delay]
      @args[:data]['transition'] = animation_attrs[:transition] if animation_attrs[:transition]
    end

    # Apply accessibility attributes (ARIA, roles)
    def apply_accessibility_attributes(a11y_attrs)
      return unless a11y_attrs.is_a?(Hash)

      # Direct ARIA attributes
      @args[:role] = a11y_attrs[:role] if a11y_attrs[:role]
      @args[:'aria-label'] = a11y_attrs[:label] if a11y_attrs[:label]
      @args[:'aria-labelledby'] = a11y_attrs[:labelledby] if a11y_attrs[:labelledby]
      @args[:'aria-describedby'] = a11y_attrs[:describedby] if a11y_attrs[:describedby]
      @args[:'aria-expanded'] = a11y_attrs[:expanded] if a11y_attrs.key?(:expanded)
      @args[:'aria-hidden'] = a11y_attrs[:hidden] if a11y_attrs.key?(:hidden)
      @args[:'aria-live'] = a11y_attrs[:live] if a11y_attrs[:live]
      @args[:tabindex] = a11y_attrs[:tabindex] if a11y_attrs[:tabindex]
    end

    # Apply responsive design attributes
    def apply_responsive_attributes(responsive_attrs)
      return unless responsive_attrs.is_a?(Hash)

      @args[:data] ||= {}
      @args[:data]['responsive'] = 'true' if responsive_attrs[:enabled]
      @args[:data]['mobile-visible'] = responsive_attrs[:mobile_visible] if responsive_attrs.key?(:mobile_visible)
      @args[:data]['tablet-visible'] = responsive_attrs[:tablet_visible] if responsive_attrs.key?(:tablet_visible)
      @args[:data]['desktop-visible'] = responsive_attrs[:desktop_visible] if responsive_attrs.key?(:desktop_visible)
      @args[:data]['breakpoint'] = responsive_attrs[:breakpoint] if responsive_attrs[:breakpoint]
    end

    # Apply interaction attributes (hover, focus, active states)
    def apply_interaction_attributes(interaction_attrs)
      return unless interaction_attrs.is_a?(Hash)

      @args[:data] ||= {}
      @args[:data]['interactive'] = 'true' if interaction_attrs[:enabled]
      @args[:data]['hover-effect'] = interaction_attrs[:hover_effect] if interaction_attrs[:hover_effect]
      @args[:data]['focus-style'] = interaction_attrs[:focus_style] if interaction_attrs[:focus_style]
      @args[:data]['click-action'] = interaction_attrs[:click_action] if interaction_attrs[:click_action]
      @args[:data]['touch-target'] = interaction_attrs[:touch_target] if interaction_attrs[:touch_target]
    end
  end
end