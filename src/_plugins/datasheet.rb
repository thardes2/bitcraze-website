require_relative 'plugin_helper'

# These plugins are used with the hardware data sheets

module Jekyll
  module Datasheet
    class DatasheetSection < Liquid::Tag
      include Jekyll::PluginHelper

      # Used to extract a section from a data sheet and inject it in the current page
      #
      # Takes two arguments:
      #   - the product to extract from, that is the directory name in src/documentation/hardware
      #   - the heading to look for
      #
      # Example
      # {% datasheet_section some-deck; Some heading %}
      #
      # The plugin will search for the heading "Some heading" in the markdown file
      # (from the hardware repo, that is in src/documentation/hardware) for the "some-deck" product.
      # The heading as well as content will be injected in the current context with some modifications of
      # heading sizes.
      #
      # If the souce markdown contains something like:

      # ----------------
      # ...
      # bla bla
      #
      # ## Features
      # * feature 1
      # * Feature 2
      #
      # ## Specifications
      # bla bla
      # ...
      # ----------------

      #
      # The use of {% datasheet_section some-deck; Features %} will inject
      #

      # #### Features
      # * feature 1
      # * Feature 2
      #

      # into the current page.

      def initialize(tag_name, text, tokens)
        super
        params = parse_args(text)

        raise "Too few arguments to 'datasheet_section' tag. Expected arguments are product name and heading" if params.length < 2

        @product_name = params[0]
        @heading = params[1]
      end

      def render(context)
        site = context.registers[:site]
        config = site.config
        src_dir = config["source"]

        product_md = load_hardware_source_md(src_dir, @product_name)
        sections = find_sections(product_md)
        section_md = extract_section(product_md, sections, @heading)

        # Increase all section levels 2 notches
        section_md_modified = section_md.gsub(/^ *#/, '###')

        context['datasheet_section_product_name'] = @product_name
        liquidify(section_md_modified, context)
      end

      def find_sections(full_md)
        full_md.enum_for(:scan, /(^ *## ) *(.*)/).map do
          index = Regexp.last_match.offset(0).first
          heading = Regexp.last_match(2)
          [heading, index]
        end
      end

      def extract_section(product_md, sections, heading)
        section_start = nil
        section_end = nil
        sections.each do |section|
          if section_start != nil
            section_end = section[1] - 1
            break
          end

          if section[0] == heading
            section_start = section[1]
          end
        end

        if section_start == nil
          raise "Section with heading '" + heading + "' could not be found"
        end

        product_md[section_start..section_end]
      end

      def load_hardware_source_md(src_dir, product_name)
        path = File.join(src_dir, 'documentation', 'hardware', product_name, 'index.md')
        File.read(path)
      end
    end

    class DatasheetImg < Liquid::Tag
      include Jekyll::PluginHelper

      # Used to insert centered images in document
      #
      # Takes one argument, the image
      #
      # Example
      # {% datasheet_img My Fancy image; medium; center; myimages/myimage.png; %}
      #
      # Supported alignment: none, always centered
      # Supported size: small, medium, large

      def initialize(tag_name, text, tokens)
        super
        params = parse_args(text)

        @title = params[0]
        @size = params[1]
        @alignment = params[2]
        @image = params[3]
      end

      def render(context)
        product_name = context['datasheet_section_product_name']
        '<img class="pp-main-image-%2$s" src="/documentation/hardware/%4$s/%3$s"  alt="%3$s"/>' % [@alignment, @size, @image, product_name]
      end
    end

  end
end

# Tags to extract content from the hardware docs
Liquid::Template.register_tag('datasheet_section', Jekyll::Datasheet::DatasheetSection)

# Tags implementing functionality used in the datasheets but with a web flavour
Liquid::Template.register_tag('datasheet_img', Jekyll::Datasheet::DatasheetImg)
# There are some more tags used in the hardware repo (pdfs) but they are currently
# not needed here and are thus not implemented (yet).
