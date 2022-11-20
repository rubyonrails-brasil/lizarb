class Liza::ControllerRendererPart < Liza::Part

  class Error < Liza::Error; end
  class RendererNotFound < Error; end
  class EmptyRenderStack < Error; end

  EMPTY_RENDER_STACK_MESSAGE = <<~STR
You called render without ERuby keys,
but the render stack is empty.
Did you forget to add ERuby keys?
  STR

  insertion do
    # EXTENSION

    def self.renderer
      Liza::ControllerRendererPart::Extension
    end

    def renderer
      @renderer ||= self.class.renderer.new self
    end

    # CLASS

    def self.controller_ancestors
      ancestors.take_while { |k| k != Liza::Controller }
    end

    def self.render_paths
      @render_paths ||= controller_ancestors.map &:source_location_radical
    end

    def render_paths
      self.class.render_paths
    end

    def self.renderers
      @renderers ||= get_renderers
    end

    def self.get_renderers
      ret = {}
      get_renderers_from_file ret
      get_renderers_from_folder ret
      ret
    end

    def self.get_renderers_from_file ret
      fname = "#{source_location_radical}.rb"
      lines = File.readlines fname

      lineno = lines.index "__END__\n"
      return if lineno.nil?

      content = lines[lineno+1..-1].join
      array = content.split(/# (\w*).(\w*).(\w*)/)
      # => ["", "a", "html", "erb", "\n<html>\n<a></a>\n</html>\n", "b", "html", "erb", "\n<html>\n<b></b>\n</html>"]

      while (chunk = array.pop 4; chunk.size == 4)
        # => ["b", "html", "erb", "\n<html>\n<b></b>\n</html>"]
        # => ["a", "html", "erb", "\n<html>\n<a></a>\n</html>\n"]
        key = "#{chunk[0]}.#{chunk[1]}.#{chunk[2]}"
        content = chunk[3]
        ret[key] = renderer.create_erb content, fname, lineno
      end
    end

    def self.get_renderers_from_folder ret
      pattern = "#{source_location_radical}/*.erb"
      fnames = Dir[pattern]
      fnames.each do |fname|
        key = fname.split("/").last
        content = File.read fname
        ret[key] = renderer.create_erb content, fname, 0
      end
    end

    # INSTANCE

    def render *keys
      if keys.any?
        log "render #{keys.join ", "}" if keys.any?
        renderer.render keys, binding
      elsif renderer.stack.any?
        renderer.stack.pop
      else
        raise EmptyRenderStack, EMPTY_RENDER_STACK_MESSAGE, caller
      end
    end
  end

  extension do
    # CLASS

    def self.create_erb content, filename, lineno
      erb = ERB.new(content)
      erb.filename, erb.lineno = filename, lineno
      erb
    end

    def self.log(...)
      solder.log(...)
    end

    # INSTANCE

    def log(...)
      self.class.log(...)
    end

    def erb_lists
      @erb_lists ||= []
    end

    def stack
      @stack ||= []
    end

    def render keys, the_binding
      erbs = erbs_for keys
      erbs.to_a.reverse.each do |key, erb|
        t = Time.now
        s = _render erb, the_binding
        t = t.diff
        log "       #{key.ljust_blanks 20} with #{s.length.to_s.rjust_blanks 4} characters in #{t}s"

        s = render_wrap_html s, erb if key.end_with?(".html")
        stack.push s
      end

      stack.pop
    end

    def _render erb, the_binding
      erb.result the_binding
    rescue StandardError => e
      puts e.full_message
      puts "backtrace:"
      puts e.backtrace
      raise
    end

    def render_wrap_html s, erb
      "<!-- #{erb.filename.split("/").last}:#{erb.lineno} -->\n#{s}\n<!-- #{erb.filename.split("/").last} -->"
    end

    def erbs_for keys
      ret = {}
      keys.each do |key|
        erb = erb_for key

        if erb
          ret[key] = erb
        else
          log "Failed to find ERuby #{"#{key}.erb".red} in #{solder.class}.render_paths"
          solder.render_paths.each { |s| log "  #{s}/#{"#{key}.erb".red}" }
          raise RendererNotFound, "Failed to find ERuby #{key}.erb"
        end
      end

      ret
    end

    def erb_for key
      key = "#{key}.erb"
      solder.class.controller_ancestors.each do |controller|
        erb = controller.renderers[key]
        return erb if erb
      end
      nil
    end
  end
end
