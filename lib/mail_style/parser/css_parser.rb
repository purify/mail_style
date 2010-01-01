require 'css_parser'

module MailStyle
  module Parser
    class CssParser < MailStyle::Parser::Base
      def initialize(css_rules)
        @parser = ::CssParser::Parser.new
        @parser.add_block!(css_rules)
      end
      
      def render_inline(html_document)
        # Write inline styles
        @document = html_document
        @element_styles = {}
        
        @parser.each_selector do |selector, declaration, specificity|
          @document.css(selector).each do |element|
            declaration.to_s.split(';').each do |style|
              # Split style in attribute and value
              attribute, value = style.split(':').map(&:strip)
              
              # Set element style defaults
              @element_styles[element] ||= {}
              @element_styles[element][attribute] ||= { :specificity => 0, :value => '' }
              
              # Update attribute value if specificity is higher than previous values
              if @element_styles[element][attribute][:specificity] <= specificity
                @element_styles[element][attribute] = { :specificity => specificity, :value => value }
              end
            end
          end
        end
        
        super
      end
    end
  end
end

