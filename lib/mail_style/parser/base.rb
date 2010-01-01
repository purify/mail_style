module MailStyle
  module Parser
    class Base
      attr_accessor :default_parser, :parser, :element_styles, :document
      
      def initialize(css_rules)
        @element_styles = {}
      end
      
      def render_inline(html_document)
        # Loop through element styles
        @element_styles.each_pair do |element, attributes|
          # Elements current styles
          current_style = element['style'].to_s.split(';').sort
          
          # Elements new styles
          new_style = attributes.map{|attribute, style| "#{attribute}: #{style[:value]}"}

          # Concat styles
          style = (current_style + new_style).compact.uniq.map(&:strip).sort

          # Set new styles
          element['style'] = style.join(';')
        end
        
        # Return document
        @document
      end
    end
  end
end