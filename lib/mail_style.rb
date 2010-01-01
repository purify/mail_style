require 'mail_style/inline_styles'

# Parsers
require 'mail_style/parser/base'
require 'mail_style/parser/css_parser'
require 'mail_style/parser/csspool'

# Renderers
require 'mail_style/renderer/sass' if defined?(Sass)

module MailStyle
  mattr_accessor :css_parser
  
  # Defaults
  @@css_parser = CssParser
  
  # Exceptions
  class CSSFileNotFound < StandardError; end
end