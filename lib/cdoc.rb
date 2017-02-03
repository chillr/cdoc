require 'cdoc/version'
require 'rake'
Bundler.require(:default)

module Cdoc
  class DocRenderer < Redcarpet::Render::HTML
    def block_code(code, lang='text')
      lang = lang && lang.split.first || "text"
      Pygments.highlight(code, lexer: lang)
      # output = add_code_tags(
      #   Pygmentize.process(code, lang), lang
      # )
    end
  end

  class DocString
    def initialize
      @docstring = ''
    end

    def title(title)
      @title = title
      @docstring << "\n" + "# #{title}" + "\n"
    end

    def section(str)
      @docstring << "\n" + "## #{str}" + "\n"
    end

    def subsection(str)
      lines = str.split("\n")
      index = 0

      loop do
        line = lines[index]

        if line.nil?
          break
        elsif m = line.match(/@\w+/)         # tag line if it start with @<tag>
          block = tagged_line(line, m[0])
        elsif line.start_with?('  ') # if the line start with 2 or more spaces
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
                block = ["\n", '```json', code_str, '```'].join("\n")
              rescue JSON::ParserError => e
                puts e.message
                block = ["\n", '```', code_str, '```'].join("\n")
              end

              break
            else
              code_block << line.sub('  ', '')
              index = index + 1
            end
          end
        else
          block = line
        end

        @docstring << block
        index = index + 1
      end

      @docstring << "\n"
    end

    def tagged_line(line, tag)
      t   = line.sub(tag, '').strip
      t_l = "\n" + tag.sub('@','').capitalize

      if !t.empty?
        t_l = t_l + " **#{t.strip}**\n\n"
      end

      t_l
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

    def render_as_html
      layout_file = File.join(File.dirname(__FILE__), 'layouts/default.html')
      layout = File.read(layout_file)
      f = File.open('doc/index.html', 'w+')
      renderer = DocRenderer.new
      markdown = Redcarpet::Markdown.new(renderer, fenced_code_blocks: true)
      html = layout % { title: @title, content: markdown.render(@docstring)}
      f.write(html)
      f.close

      unless Dir.exists?('doc/css')
        puts File.join(File.dirname(__FILE__), 'styles')
        FileUtils.cp_r(File.join(File.dirname(__FILE__), 'styles'), 'doc/css')
      end
    end
  end

  class CDoc

    attr_accessor :files, :docstring

    def initialize
      @files = Rake::FileList.new('app/controllers/**/*.rb')
      @files = @files.select { |file| file.end_with?('_controller.rb') }
      @doc = DocString.new
    end

    def generate
      @doc.title('Chillr API Documentaion')

      @file_groups = files.group_by { |f| File.basename(f, '_controller.rb') }

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
