# This "hook" is executed right before the site's pages are rendered
Jekyll::Hooks.register :site, :pre_render do |site|
  puts "Adding more PureScript Markdown aliases..."
  require "rouge"

  # This class defines the PDL lexer which is used to highlight "pdl" code snippets during render-time
  class Purescript < Rouge::Lexers::Typescript
    title 'Purescript'
    aliases 'ps'
  end
end