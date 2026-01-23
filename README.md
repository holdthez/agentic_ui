# AgenticUI 🤖

> Revolutionary YAML-driven UI component system designed for AI-controlled interfaces and agentic CMS platforms

[![Ruby Gem](https://img.shields.io/badge/ruby-3.1%2B-red.svg)](https://ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-7.0%2B-blue.svg)](https://rubyonrails.org)
[![CSS Layers](https://img.shields.io/badge/css-layers-green.svg)](https://developer.mozilla.org/en-US/docs/Web/CSS/@layer)

## 🎯 Core Philosophy

AgenticUI is built on the revolutionary principle that **AI agents should control UI components dynamically** through declarative YAML configuration. Every component is AI-controllable by default, with personality-driven theming and agent-aware styling.

## ✨ Revolutionary Features

### 🤖 **AI-Controllable Components**
- Every component supports AI commands like `theme`, `layout`, `animate`
- Agent personalities drive dynamic styling
- Real-time UI adaptation based on agent preferences

### 🎨 **6-Layer CSS Architecture**
```css
@layer foundation, framework, agentic-layout, agentic-components, agentic-interactive, agentic-utilities;
```

### 🎯 **YAML-Driven Configuration**
- Zero hardcoded CSS classes
- Declarative component definitions
- Agent-aware responsive behavior

### 🚀 **UnifiedTheme Integration**
- 451+ CSS custom properties
- Thread-safe variable management
- Personality-driven theme variations

## 🚀 Quick Start

### Installation

Add to your Gemfile:
```ruby
gem 'agentic_ui', path: './agentic_ui'
```

### Basic Usage

```erb
<!-- Traditional Rails way -->
<div class="widget">
  <div class="header">Welcome</div>
  <div class="content">Content here</div>
</div>

<!-- Revolutionary AgenticUI way -->
<%= ux.widget do %>
  <%= ux.header "Welcome" %>
  <%= ux.content "Content here" %>
<% end %>
```

### AI-Controlled Components

```erb
<!-- AI can dynamically control these components -->
<%= ux.card theme: "professional", animate: "fade-in" do %>
  <%= ux.button style: "primary", personality: "technical" %>
<% end %>
```

## 🎨 Component Architecture

### Core Layout Components
- `ux.container` - Responsive containers with agent-aware spacing
- `ux.grid` - CSS Grid with AI-controllable columns and gaps
- `ux.column` - Grid columns with responsive behavior

### Interactive Components
- `ux.button` - AI-themed buttons with personality styling
- `ux.input` - Form fields with agent-aware validation
- `ux.form` - Enhanced forms with Stimulus integration

### Content Components
- `ux.widget` - Revolutionary widget system with agent control
- `ux.card` - Smart cards with elevation and theming
- `ux.content` - Typography with agent preferences

## 🤖 Agent Context System

### Setting Agent Context

```ruby
# In your controller
def show
  agent_session = AgentSession.find(params[:id])
  @agent_context = AgenticUi::AgentContext.from_agent_session(agent_session)
end
```

```erb
<!-- In your view -->
<% set_agent_context(@agent_context) %>
<%= agentic_css_layers %>
<%= agentic_css_variables %>

<div <%= agent_context.data_attributes %>>
  <%= ux.widget personality: "professional" do %>
    <%= ux.header "Agent-Aware Header" %>
  <% end %>
</div>
```

### Agent Personalities

- **Professional**: Clean, minimal, corporate styling
- **Casual**: Rounded corners, friendly animations
- **Technical**: Monospace fonts, precise spacing

## 📐 CSS Layers Architecture

AgenticUI implements a revolutionary 6-layer CSS cascade:

### 1. Foundation Layer
- CSS custom properties
- Agent-specific variables
- Theme foundation

### 2. Framework Layer
- Base resets and normalizations
- Core component behaviors

### 3. Agentic Layout Layer
- Grid systems and containers
- Responsive layout utilities

### 4. Agentic Components Layer
- Widget and card styling
- Content and typography

### 5. Agentic Interactive Layer
- Buttons and form controls
- Interactive element styling

### 6. Agentic Utilities Layer
- Agent-aware utilities
- AI control indicators

## 🎯 YAML Configuration

Components are defined in `config/agentic_ui.yml`:

```yaml
ui:
  widget:
    tag: div
    css_class: 'widget'
    ai_controllable: true
    ai_commands: ['theme', 'layout', 'animate', 'personality']
    css_layer: 'agentic-components'
    agent_aware: true
    stimulus_controller: 'agentic-widget'
    unified_theme_vars: ['--widget-background', '--widget-shadow']
```

## 🚀 Integration Examples

### With Stimulus Controllers

```erb
<%= ux.dropdown controller: "enhanced-dropdown" do %>
  <%= ux.button "Toggle Dropdown" %>
  <%= ux.menu do %>
    <%= ux.link "Option 1", to: path_helper %>
  <% end %>
<% end %>
```

### With Form Helpers

```erb
<%= ux.form model: @user do |f| %>
  <%= ux.input type: "text", placeholder: "Name" %>
  <%= ux.button "Submit", type: "submit" %>
<% end %>
```

### With UnifiedTheme

```erb
<!-- Automatic CSS variable integration -->
<%= ux.card do %>
  <% # Uses --card-background, --card-shadow, etc. %>
  <%= ux.content "Themed content" %>
<% end %>
```

## 🔧 Advanced Configuration

### Custom Component Registration

```ruby
AgenticUi.configure do |config|
  config.register_component :custom_widget,
    tag: 'section',
    css_class: 'custom-widget',
    ai_controllable: true,
    ai_commands: ['theme', 'layout'],
    css_layer: 'agentic-components'
end
```

### Agent Context Management

```ruby
# Thread-safe context switching
AgenticUi::AgentContext.with_context(professional_context) do
  # All UI components use professional styling
  render 'dashboard'
end
```

## 🎨 Theming System

### CSS Custom Properties

AgenticUI automatically generates CSS variables:

```css
:root {
  --agent-primary: #2563eb;
  --agent-surface: #ffffff;
  --agent-text: #1f2937;
  --agent-personality: professional;
  --agentic-border-radius: 4px;
  --agentic-shadow-intensity: 0.08;
}
```

### Component-Specific Variables

```css
.widget {
  background: var(--agentic-widget-background, var(--agent-surface));
  border-radius: var(--agentic-widget-radius, var(--agent-border-radius));
  box-shadow: var(--agentic-widget-shadow, var(--agent-shadow));
}
```

## 🧪 Testing

### RSpec Integration

```ruby
RSpec.describe "AgenticUI Components" do
  let(:agent_context) { AgenticUi::AgentContext.new(personality: 'technical') }
  
  it "renders AI-controllable components" do
    AgenticUi::AgentContext.with_context(agent_context) do
      component = AgenticUi::WrapperComponent.new(:widget, theme: 'dark')
      expect(component.ai_controllable?).to be true
    end
  end
end
```

### Playwright Testing

```typescript
import { test, expect } from '@playwright/test';

test('AI-controllable components', async ({ page }) => {
  await page.goto('/dashboard');
  
  // Check for AI control indicators
  const widget = page.locator('[data-ai-controllable="true"]');
  await expect(widget).toHaveAttribute('data-ai-commands', 'theme,layout,animate');
});
```

## 🔒 Security

- **XSS Protection**: All user inputs are sanitized
- **CSS Injection Prevention**: Validates CSS property names
- **Agent Context Isolation**: Thread-safe context management

## 🚀 Performance

- **CSS Layers**: Optimal cascade performance
- **Variable Caching**: Efficient CSS custom property management
- **Lazy Loading**: Components load only when needed

## 📚 API Reference

### Core Classes

- `AgenticUi::Display` - Main component factory
- `AgenticUi::WrapperComponent` - Component wrapper with Rails integration
- `AgenticUi::AgentContext` - Agent-aware context management
- `AgenticUi::CssLayers` - 6-layer CSS architecture
- `AgenticUi::Configuration` - YAML-driven configuration

### Helper Methods

- `ux` - Access to component factory
- `set_agent_context(context)` - Set current agent context
- `agentic_css_layers` - Render CSS layers
- `agentic_css_variables` - Render agent variables

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Follow TDD principles - tests first!
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 🙏 Acknowledgments

- Built for the revolutionary **StoryPRO Platform**
- Inspired by the future of **Agentic CMS** architecture
- Powered by **Rails 8.0.2** and modern CSS

---

**AgenticUI** - *Where AI meets UI* 🤖✨
