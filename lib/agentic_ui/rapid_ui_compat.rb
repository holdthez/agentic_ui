# frozen_string_literal: true

module AgenticUi
  # RapidUI Backward Compatibility Layer
  # Provides 100% backward compatibility with RapidUI features
  # while preserving revolutionary AgenticUI agent-aware enhancements
  module RapidUiCompat
    # Convert numbers to words for Semantic UI grid system
    # Example: 4 → "four", 16 → "sixteen"
    def number_in_words(int)
      numbers_to_name = {
        1_000_000 => 'million', 1000 => 'thousand', 100 => 'hundred',
        90 => 'ninety', 80 => 'eighty', 70 => 'seventy', 60 => 'sixty',
        50 => 'fifty', 40 => 'forty', 30 => 'thirty', 20 => 'twenty',
        19 => 'nineteen', 18 => 'eighteen', 17 => 'seventeen', 16 => 'sixteen',
        15 => 'fifteen', 14 => 'fourteen', 13 => 'thirteen', 12 => 'twelve',
        11 => 'eleven', 10 => 'ten', 9 => 'nine', 8 => 'eight', 7 => 'seven',
        6 => 'six', 5 => 'five', 4 => 'four', 3 => 'three', 2 => 'two', 1 => 'one'
      }

      str = ''
      numbers_to_name.each do |num, name|
        if int.zero?
          return str
        elsif int.to_s.length == 1 && (int / num).positive?
          return str + name.to_s
        elsif int < 100 && (int / num).positive?
          return str + name.to_s if (int % num).zero?
          return str + name.to_s + ' ' + number_in_words(int % num)
        elsif (int / num).positive?
          return str + number_in_words(int / num) + ' ' + name.to_s + ' ' + number_in_words(int % num)
        end
      end

      str.strip
    end

    # Build responsive grid size classes (Semantic UI)
    # Example: build_size(:mobile, 2) → "two wide mobile"
    def build_size(device = nil, size_value = nil)
      return number_in_words(size_value) if device.nil?
      "#{number_in_words(size_value)} wide #{device}"
    end

    # Build 'only' display class (Semantic UI)
    # Example: build_only('mobile') → "mobile only"
    def build_only(value)
      "#{value} only"
    end

    # Apply Stimulus.js shortcuts: c:, a:, t:, p:, v:
    # Modifies args hash in place
    def apply_stimulus_shortcuts!(args)
      args[:controller] = args[:c] if args.key?(:c)
      args[:action] = args[:a] if args.key?(:a)
      args[:target] = args[:t] if args.key?(:t)
      args[:params] = args[:p] if args.key?(:p)
      args[:values] = args[:v] if args.key?(:v)

      # Clean up shortcut keys
      args.delete(:c)
      args.delete(:a)
      args.delete(:t)
      args.delete(:p)
      args.delete(:v)

      args
    end

    # Add Stimulus target data attributes
    # Example: { dropdown: 'button' } → { 'dropdown-target' => 'button' }
    def add_target_data(args, target_obj)
      args[:data] ||= {}

      target_obj.each do |controller, target|
        data_key = "#{controller}-target"
        args[:data][data_key] = target.to_s
      end

      args
    end

    # Add Stimulus params data attributes
    # Example: { dropdown: { url: '/api' } } → { 'dropdown-url-param' => '/api' }
    def add_params_data(args, params_obj)
      args[:data] ||= {}

      params_obj.each do |controller, params|
        params.each do |param_name, param_value|
          data_key = "#{controller}-#{param_name}-param"
          args[:data][data_key] = param_value.to_s
        end
      end

      args
    end

    # Add Stimulus values data attributes
    # Example: { dropdown: { count: 0 } } → { 'dropdown-count-value' => '0' }
    def add_values_data(args, values_obj)
      args[:data] ||= {}

      values_obj.each do |controller, values|
        values.each do |value_name, value|
          data_key = "#{controller}-#{value_name}-value"
          args[:data][data_key] = value.to_s
        end
      end

      args
    end

    # Build responsive grid classes for all device types
    # Modifies args[:class] to include responsive grid classes
    def build_responsiveness!(args)
      responsive_classes = []

      # Handle 'only' parameter (e.g., only: 'mobile')
      if args.key?(:only)
        responsive_classes << build_only(args[:only])
        args.delete(:only)
      end

      # Handle 'size' parameter (e.g., size: 4 → "four")
      if args.key?(:size)
        responsive_classes << number_in_words(args[:size])
        args.delete(:size)
      end

      # Handle device-specific sizes (e.g., mobile: 2, tablet: 4, computer: 6)
      %i[computer tablet mobile].each do |device|
        if args.key?(device)
          responsive_classes << build_size(device, args[device])
          args.delete(device)
        end
      end

      # Add responsive classes to existing class string
      if responsive_classes.any?
        existing_class = args[:class] || ''
        args[:class] = [existing_class, responsive_classes.join(' ')].reject(&:empty?).join(' ')
      end

      args
    end

    # Build component name and data attributes
    # Example: name: 'User Profile' → class includes 'User Profile', data-name="user_profile"
    def build_name!(args)
      return args unless args.key?(:name)

      name = args[:name]

      # Add name as CSS class
      existing_class = args[:class] || ''
      args[:class] = [existing_class, name].reject(&:empty?).join(' ')

      # Add name as data attribute (parameterized)
      args[:data] ||= {}
      args[:data][:name] = name.parameterize.underscore

      # Remove :name from args
      args.delete(:name)

      args
    end

    # Build 'ui' class (Semantic UI compatibility)
    # Adds "ui" class unless ui: false is specified
    def build_ui_class!(args, config)
      # Check if ui: false is explicitly set
      ui_disabled = args.key?(:ui) && args[:ui] == false
      args.delete(:ui) # Remove :ui key regardless

      return args if ui_disabled

      # Add "ui" class if not disabled
      existing_class = args[:class] || ''
      args[:class] = ['ui', existing_class].reject(&:empty?).join(' ')

      args
    end

    # Build 'dynamic' class (RapidUI feature)
    # Adds "dynamic" class if dynamic: true is specified
    def build_dynamic_class!(args)
      return args unless args.key?(:dynamic) && args[:dynamic]

      existing_class = args[:class] || ''
      args[:class] = [existing_class, 'dynamic'].reject(&:empty?).join(' ')

      args.delete(:dynamic)

      args
    end

    # Process all Stimulus.js related arguments
    def process_stimulus!(args)
      # Apply shortcuts first
      apply_stimulus_shortcuts!(args)

      # Add data attributes for target, params, values
      add_target_data(args, args[:target]) if args.key?(:target)
      add_params_data(args, args[:params]) if args.key?(:params)
      add_values_data(args, args[:values]) if args.key?(:values)

      # Clean up processed keys
      args.delete(:target)
      args.delete(:params)
      args.delete(:values)

      # Keep :controller and :action for standard Stimulus data attribute handling
      args
    end

    # Complete RapidUI argument processing
    # This method applies ALL RapidUI transformations to args
    def process_rapid_ui_args!(args, config)
      # 1. Build UI class (Semantic UI compatibility)
      build_ui_class!(args, config)

      # 2. Build dynamic class
      build_dynamic_class!(args)

      # 3. Build responsive grid classes
      build_responsiveness!(args)

      # 4. Build component name and data attributes
      build_name!(args)

      # 5. Process all Stimulus.js features
      process_stimulus!(args)

      args
    end
  end
end
