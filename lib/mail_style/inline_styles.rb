require 'uri'
require 'nokogiri'

module MailStyle
  module InlineStyles
    DOCTYPE = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
    
    module InstanceMethods
      def create_mail_with_inline_styles
        write_inline_styles if @css.present?
        create_mail_without_inline_styles
      end
      
      protected
      
      def write_inline_styles
        # Parse only text/html parts
        @parts.select{|p| p.content_type == 'text/html'}.each do |part|
          part.body = parse_html(part.body)
        end
        
        # Parse single part emails if the body is html
        real_content_type, ctype_attrs = parse_content_type
        self.body = parse_html(body) if body.is_a?(String) && real_content_type == 'text/html'
      end

      def parse_html(html)
        # Parse original html
        html_document = create_html_document(html)
        html_document = absolutize_image_sources(html_document)
        
        # Render styles inline
        html_document = css_parser.render_inline(html_document)
        
        # Strip all references to classes.
        html_document.css('*').remove_class
        html = absolutize_background_image_urls(html_document.to_html)
      end
      
      # Fix the urls of background images in css
      def absolutize_background_image_urls(html)
        html.scan(/url\(['"]?(.*)['"]?\)/).flatten.each do |url|
          html.gsub!(url, absolutize_url(url, 'stylesheets'))
        end
        
        html
      end
      
      # Fix the source of <img /> tag
      def absolutize_image_sources(document)
        document.css('img').each do |img|
          src = img['src']
          img['src'] = src.gsub(src, absolutize_url(src))
        end
        
        document
      end
      
      # TODO: Refactor this ugly method
      def css_parser
        "MailStyle::Parser::#{MailStyle.css_parser}".constantize.new(css_rules)
      end
      
      # Create Nokogiri html document from part contents and add/amend certain elements.
      # Reference: http://www.creativeglo.co.uk/email-design/html-email-design-and-coding-tips-part-2/
      def create_html_document(body)
        # Add doctype to html along with body
        document = Nokogiri::HTML.parse(DOCTYPE + body)
        
        # Set some meta stuff
        html = document.at_css('html')
        html['xmlns'] = 'http://www.w3.org/1999/xhtml'
        
        # Create <head> element if missing
        head = document.at_css('head')
        
        unless head.present?
          head = Nokogiri::XML::Node.new('head', document)
          document.at_css('body').add_previous_sibling(head)
        end
        
        # Add utf-8 content type meta tag
        meta = Nokogiri::XML::Node.new('meta', document)
        meta['http-equiv'] = 'Content-Type'
        meta['content'] = 'text/html; charset=utf-8'
        head.add_child(meta)
        
        # Return document
        document
      end
      
      # Update image urls
      def update_image_urls(style)
        if default_url_options[:host].present?
          # Replace urls in stylesheets
          style.gsub!($1, absolutize_url($1, 'stylesheets')) if style[/url\(['"]?(.*)['"]?\)/i]
        end
        
        style
      end
      
      # Absolutize URL (Absolutize? Seriously?)
      def absolutize_url(url, base_path = '')
        original_url = url
        
        unless original_url[URI::regexp(%w[http https])]
          # Calculate new path
          host = default_url_options[:host]
          url = URI.join("http://#{host}/", File.join(base_path, original_url)).to_s
        end
        
        url
      end

      # Css Rules
      def css_rules
        File.read(css_file)
      end
      
      # Find the css file
      def css_file
        if @css.present?
          css = @css.to_s
          css = css[/\.css$/] ? css : "#{css}.css"
          path = File.join(RAILS_ROOT, 'public', 'stylesheets', css)
          File.exist?(path) ? path : raise(CSSFileNotFound)
        end
      end
    end
    
    def self.included(receiver)
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        adv_attr_accessor :css
        alias_method_chain :create_mail, :inline_styles
      end
    end
  end
end

ActionMailer::Base.send :include, MailStyle::InlineStyles