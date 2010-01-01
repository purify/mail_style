require 'csspool'

module MailStyle
  module Parser
    class CSSPool < MailStyle::Parser::Base
      def initialize(css_rules)
        @parser = ::CSSPool.CSS(css_rules)
      end
      
      def render_inline(html_document)
        # Write inline styles
        @document = html_document
        @element_styles = {}
        
        # Parse rules
        @parser.rule_sets.each do |rule_set|
          rule_set.selectors.each do |selector|
            @document.css(selector.to_s).each do |element|
              selector.declarations.each do |declaration|
                # Split style in attribute and value
                attribute, value = declaration.to_s.split(':').map{|str| str.strip.gsub(';', '')}
                
                # 14px should be 14px not 14.0px. Stupid floats.
                value = value.gsub($1, $2) if value[/((\d+)\.0)/]

                # Set element style defaults
                @element_styles[element] ||= {}
                @element_styles[element][attribute] ||= { :specificity => '0', :value => '' }

                # Update attribute value if specificity is higher than previous values
                if @element_styles[element][attribute][:specificity] <= selector.specificity.to_s
                  @element_styles[element][attribute] = { :specificity => selector.specificity.to_s, :value => value }
                end
              end
            end
          end
        end
      
        super
      end
    end
  end
end

