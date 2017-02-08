require 'cdoc/version'
require 'rake'
require 'redcarpet'
require 'pygments'
require 'json'

module Cdoc

  module Helpers
    def to_id(str)
      str.gsub(/\W/, '').downcase
    end
  end

  class DocRenderer < Redcarpet::Render::HTML
    def block_code(code, lang='text')
      lang = lang && lang.split.first || "text"
      Pygments.highlight(code, lexer: lang)
    end
  end

  class DocString

    include Helpers

    def initialize
      @docstring = ''
      @content = []
    end

    def title(title)
      @title = title
    end

    def section(str)
      template = "<p id='%{id}'><h3>%{str}</h3></p>"
      @content <<  template % { id: to_id(str), str: str }
    end

    def sidebar(sidebar)
      @sidebar = sidebar
    end

    def subsection(str)

      template = %q(
      <div class="panel panel-default" id="accounts">
        <div class="panel-heading">
          <h3 class="panel-title">%{section_header}</h3>
        </div>
        <div class="panel-body">
          %{section_body}
        </div>
      </div>)

          lines = str.split("\n")
      index = 0
      section_header = ''
      sub_section = []

      loop do
        line = lines[index]

        if line.nil?
          break
        elsif m = line.match(/@\w+/)         # tag line if it start with @<tag>
          block = tagged_line(line, m[0])
        elsif line.start_with?('  ')         # if the line start with 2 or more spaces
          code_block = []
          code_block << line.sub('  ', '')

          loop do
            line = lines[index + 1]

            if line.nil? || !line.start_with?('  ')
              code_str = code_block.join("\n")
              # try to parse this as json
              begin
                json = JSON.parse(code_str)
                code_str = JSON.pretty_generate(json)
                block = ['<pre><code>', code_str, '</code></pre>'].join('')
              rescue JSON::ParserError => e
                # puts e.message
                block = ['<pre><code>', code_str, '</code></pre>'].join("\n")
              end

              break
            else
              code_block << line.sub('  ', '') unless line.strip.empty?
              index = index + 1
            end
          end
        else
          block = [line, '<br/>'].join('')
        end

        if index == 0
          section_header = block
        else
          sub_section << block
        end

        index = index + 1
      end

      @content << template % { section_header: section_header, section_body: sub_section.join("\n")}
    end

    def tagged_line(line, tag)
      if ['url', 'endpoint', 'api'].include?(tag.downcase)
        # set the title of the section
      end

      t   = line.sub(tag, '').strip
      t_l = ['<small>', tag.sub('@', '').capitalize, '</small>']

      if !t.empty?
        t_l = t_l + ['<strong>', t.strip, '</strong>']
      end

      ['<p>', t_l, '</p>'].flatten.join("\n")
    end

    def finish
      FileUtils.mkdir_p('doc') unless Dir.exists?('doc')
      render_as_markdown
      render_as_html
    end

    def render_as_markdown
      f = File.open('doc/index.md', 'w+')
      f.write(@docstring)
      f.close
    end

    def content
      @content.flatten.join('')
    end

    def render_as_html
      layout_file = File.join(File.dirname(__FILE__), 'layouts/bootstrap.html')
      layout = File.read(layout_file)
      f = File.open('doc/index.html', 'w+')
      renderer = DocRenderer.new
      markdown = Redcarpet::Markdown.new(renderer, fenced_code_blocks: true)
      html = layout % { title: @title, sidebar: @sidebar, content: content }
      f.write(html)
      f.close

      unless Dir.exists?('doc/css')
        puts File.join(File.dirname(__FILE__), 'styles')
        FileUtils.cp_r(File.join(File.dirname(__FILE__), 'styles'), 'doc/css')
      end
    end
  end

  class CDoc

    include Helpers

    attr_accessor :files, :docstring

    def initialize
      @files = Rake::FileList.new('app/controllers/**/*.rb')
      @files = @files.select { |file| file.end_with?('_controller.rb') }
      @doc = DocString.new
    end

    def generate_sidebar(keys)
      tmpl_item = '<a href="#%{id}" class="list-group-item">%{item}</a>'

      items = keys.map do |key|
        tmpl_item % { id: to_id(key), item: key.capitalize }
      end

      ['<div class="list-group">', items, '</div>'].flatten.join("\n")
    end

    def generate
      @doc.title('Chillr API Documentaion')

      @file_groups = files.group_by { |f| File.basename(f, '_controller.rb') }

      sidebar = generate_sidebar(@file_groups.keys)

      @doc.sidebar(sidebar)

      @file_groups.each do |group, files|
        @doc.section(group.capitalize)
        files.each do |file|
          docs = extract_documentation(file)
          docs.each do |doc|
            @doc.subsection(doc)
          end
        end
      end

      @doc.finish
    end

    def extract_documentation(file)
      begin
        lines = File.readlines(file)
      rescue => e
        puts "#{e.class}: Error reading file #{file}. Skip"
        return
      end

      docs  = []
      doclines = []
      recording = false

      lines.each do |line|
        if !recording && (line.strip == '#doc')
          recording = true
          next
        end

        if recording
          line = line.strip

          if line.empty?
            next
          elsif line.start_with?('#')
            doclines << line.strip.sub('#', '')
          else
            recording = false
            docs << doclines.join("\n")
            doclines = []
          end
        end
      end

      if recording && (doclines.length != 0)
        recording = false
        docs << doclines.join("\n")
        doclines = []
      end

      docs
    end
  end
end
