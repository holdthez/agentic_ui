# frozen_string_literal: true

require 'test_helper'

class RapidUiCompatTest < ActiveSupport::TestCase
  include AgenticUi::RapidUiCompat

  # Number-to-Words Conversion Tests
  test "number_in_words converts 1-20" do
    assert_equal 'one', number_in_words(1)
    assert_equal 'two', number_in_words(2)
    assert_equal 'three', number_in_words(3)
    assert_equal 'four', number_in_words(4)
    assert_equal 'five', number_in_words(5)
    assert_equal 'sixteen', number_in_words(16)
    assert_equal 'twenty', number_in_words(20)
  end

  test "number_in_words converts tens" do
    assert_equal 'thirty', number_in_words(30)
    assert_equal 'forty', number_in_words(40)
    assert_equal 'fifty', number_in_words(50)
    assert_equal 'sixty', number_in_words(60)
  end

  test "number_in_words converts hundreds" do
    assert_equal 'one hundred', number_in_words(100)
    assert_equal 'two hundred', number_in_words(200)
  end

  # Responsive Grid Builder Tests
  test "build_size with no device returns number in words" do
    result = build_size(nil, 4)
    assert_equal 'four', result
  end

  test "build_size with device builds responsive class" do
    result = build_size(:mobile, 2)
    assert_equal 'two wide mobile', result

    result = build_size(:tablet, 4)
    assert_equal 'four wide tablet', result

    result = build_size(:computer, 8)
    assert_equal 'eight wide computer', result
  end

  # Build Only Tests
  test "build_only creates only display class" do
    result = build_only('mobile')
    assert_equal 'mobile only', result
  end

  # Stimulus Shortcuts Tests
  test "apply_stimulus_shortcuts! expands c: to controller:" do
    args = { c: 'dropdown' }
    result = apply_stimulus_shortcuts!(args)

    assert_equal 'dropdown', result[:controller]
    assert_nil result[:c]
  end

  test "apply_stimulus_shortcuts! expands a: to action:" do
    args = { a: 'click->dropdown#toggle' }
    result = apply_stimulus_shortcuts!(args)

    assert_equal 'click->dropdown#toggle', result[:action]
    assert_nil result[:a]
  end

  test "apply_stimulus_shortcuts! expands all shortcuts" do
    args = {
      c: 'dropdown',
      a: 'click->dropdown#toggle',
      t: { dropdown: 'button' },
      p: { dropdown: { url: '/api' } },
      v: { dropdown: { count: 0 } }
    }
    result = apply_stimulus_shortcuts!(args)

    assert_equal 'dropdown', result[:controller]
    assert_equal 'click->dropdown#toggle', result[:action]
    assert_equal({ dropdown: 'button' }, result[:target])
    assert_equal({ dropdown: { url: '/api' } }, result[:params])
    assert_equal({ dropdown: { count: 0 } }, result[:values])

    # Shortcuts should be removed
    assert_nil result[:c]
    assert_nil result[:a]
    assert_nil result[:t]
    assert_nil result[:p]
    assert_nil result[:v]
  end

  # Stimulus Target Data Tests
  test "add_target_data creates target data attributes" do
    args = {}
    target_obj = { dropdown: 'button', menu: 'list' }
    result = add_target_data(args, target_obj)

    assert_equal 'button', result[:data]['dropdown-target']
    assert_equal 'list', result[:data]['menu-target']
  end

  # Stimulus Params Data Tests
  test "add_params_data creates params data attributes" do
    args = {}
    params_obj = { dropdown: { url: '/api/items', method: 'GET' } }
    result = add_params_data(args, params_obj)

    assert_equal '/api/items', result[:data]['dropdown-url-param']
    assert_equal 'GET', result[:data]['dropdown-method-param']
  end

  # Stimulus Values Data Tests
  test "add_values_data creates values data attributes" do
    args = {}
    values_obj = { dropdown: { count: 0, open: true } }
    result = add_values_data(args, values_obj)

    assert_equal '0', result[:data]['dropdown-count-value']
    assert_equal 'true', result[:data]['dropdown-open-value']
  end

  # Responsiveness Builder Tests
  test "build_responsiveness! handles only parameter" do
    args = { only: 'mobile', class: 'existing' }
    result = build_responsiveness!(args)

    assert_includes result[:class], 'mobile only'
    assert_includes result[:class], 'existing'
    assert_nil result[:only]
  end

  test "build_responsiveness! handles size parameter" do
    args = { size: 4 }
    result = build_responsiveness!(args)

    assert_equal 'four', result[:class]
    assert_nil result[:size]
  end

  test "build_responsiveness! handles device-specific sizes" do
    args = { mobile: 2, tablet: 4, computer: 8 }
    result = build_responsiveness!(args)

    assert_includes result[:class], 'two wide mobile'
    assert_includes result[:class], 'four wide tablet'
    assert_includes result[:class], 'eight wide computer'

    assert_nil result[:mobile]
    assert_nil result[:tablet]
    assert_nil result[:computer]
  end

  test "build_responsiveness! combines all parameters" do
    args = { only: 'desktop', size: 6, mobile: 16, class: 'column' }
    result = build_responsiveness!(args)

    assert_includes result[:class], 'desktop only'
    assert_includes result[:class], 'six'
    assert_includes result[:class], 'sixteen wide mobile'
    assert_includes result[:class], 'column'
  end

  # Name Builder Tests
  test "build_name! adds name as class and data attribute" do
    args = { name: 'User Profile' }
    result = build_name!(args)

    assert_includes result[:class], 'User Profile'
    assert_equal 'user_profile', result[:data][:name]
    assert_nil result[:name]
  end

  # UI Class Builder Tests
  test "build_ui_class! adds ui class by default" do
    args = {}
    config = {}
    result = build_ui_class!(args, config)

    assert_includes result[:class], 'ui'
  end

  test "build_ui_class! does not add ui class when ui: false" do
    args = { ui: false }
    config = {}
    result = build_ui_class!(args, config)

    assert_nil result[:class]
    assert_nil result[:ui]
  end

  test "build_ui_class! preserves existing classes" do
    args = { class: 'segment basic' }
    config = {}
    result = build_ui_class!(args, config)

    assert_includes result[:class], 'ui'
    assert_includes result[:class], 'segment basic'
  end

  # Dynamic Class Builder Tests
  test "build_dynamic_class! adds dynamic class when true" do
    args = { dynamic: true }
    result = build_dynamic_class!(args)

    assert_includes result[:class], 'dynamic'
    assert_nil result[:dynamic]
  end

  test "build_dynamic_class! does nothing when false" do
    args = { dynamic: false }
    result = build_dynamic_class!(args)

    assert_nil result[:class]
  end

  # Complete Processing Tests
  test "process_rapid_ui_args! applies all transformations" do
    args = {
      ui: true,
      dynamic: true,
      mobile: 2,
      tablet: 4,
      computer: 6,
      name: 'User Profile',
      c: 'dropdown',
      a: 'click->dropdown#toggle',
      t: { dropdown: 'button' },
      class: 'custom'
    }
    config = {}

    result = process_rapid_ui_args!(args, config)

    # UI class
    assert_includes result[:class], 'ui'

    # Dynamic class
    assert_includes result[:class], 'dynamic'

    # Responsive grid
    assert_includes result[:class], 'two wide mobile'
    assert_includes result[:class], 'four wide tablet'
    assert_includes result[:class], 'six wide computer'

    # Name
    assert_includes result[:class], 'User Profile'
    assert_equal 'user_profile', result[:data][:name]

    # Stimulus
    assert_equal 'dropdown', result[:controller]
    assert_equal 'click->dropdown#toggle', result[:action]
    assert_equal 'button', result[:data]['dropdown-target']

    # Custom class preserved
    assert_includes result[:class], 'custom'

    # Processed keys removed
    assert_nil result[:ui]
    assert_nil result[:dynamic]
    assert_nil result[:mobile]
    assert_nil result[:name]
    assert_nil result[:c]
    assert_nil result[:t]
  end

  # Real-World Usage Patterns Tests
  test "real-world pattern: semantic UI segment" do
    args = { class: 'basic' }
    config = {}
    result = process_rapid_ui_args!(args, config)

    # ux.segment('basic') → <div class="ui basic segment">
    assert_includes result[:class], 'ui'
    assert_includes result[:class], 'basic'
  end

  test "real-world pattern: responsive grid column" do
    args = { mobile: 16, tablet: 8, computer: 4 }
    config = {}
    result = process_rapid_ui_args!(args, config)

    # ux.column(mobile: 16, tablet: 8, computer: 4)
    assert_includes result[:class], 'sixteen wide mobile'
    assert_includes result[:class], 'eight wide tablet'
    assert_includes result[:class], 'four wide computer'
  end

  test "real-world pattern: stimulus dropdown button" do
    args = {
      c: 'dropdown',
      a: 'click->dropdown#toggle',
      t: { dropdown: 'button' },
      p: { dropdown: { url: '/api/items' } }
    }
    config = {}
    result = process_rapid_ui_args!(args, config)

    # ux.button(c: 'dropdown', a: 'click->dropdown#toggle', ...)
    assert_equal 'dropdown', result[:controller]
    assert_equal 'click->dropdown#toggle', result[:action]
    assert_equal 'button', result[:data]['dropdown-target']
    assert_equal '/api/items', result[:data]['dropdown-url-param']
  end

  test "real-world pattern: named widget with ui disabled" do
    args = { name: 'User Profile', ui: false, dynamic: true }
    config = {}
    result = process_rapid_ui_args!(args, config)

    # ux.widget(name: 'User Profile', ui: false, dynamic: true)
    assert_includes result[:class], 'User Profile'
    assert_includes result[:class], 'dynamic'
    assert_not_includes result[:class], 'ui' if result[:class]
    assert_equal 'user_profile', result[:data][:name]
  end
end
