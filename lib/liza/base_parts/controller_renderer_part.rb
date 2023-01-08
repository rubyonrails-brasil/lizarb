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
      renderers = {}
      get_renderers_from_file renderers
      get_renderers_from_folder renderers
      renderers
    end

    def self.get_renderers_from_file renderers
      fname = "#{source_location_radical}.rb"
      lines = File.readlines fname

      lineno = lines.index "__END__\n"
      return if lineno.nil?

      content = lines[lineno+1..-1].join
      array = content.split(/^# (\w*).(\w*).(\w*)$/)
      # => ["", "a", "html", "erb", "\n<html>\n<a></a>\n</html>\n", "b", "html", "erb", "\n<html>\n<b></b>\n</html>"]

      while (chunk = array.pop 4; chunk.size == 4)
        # => ["b", "html", "erb", "\n<html>\n<b></b>\n</html>"]
        # => ["a", "html", "erb", "\n<html>\n<a></a>\n</html>\n"]
        key = "#{chunk[0]}.#{chunk[1]}.#{chunk[2]}"
        content = chunk[3]
        renderers[key] = Liza::Erb.from_file key, content, fname, lineno
      end
    end

    def self.get_renderers_from_folder renderers
      pattern = "#{source_location_radical}/*.erb"
      fnames = Dir[pattern]
      fnames.each do |fname|
        key = fname.split("/").last
        content = File.read fname
        renderers[key] = Liza::Erb.from_folder key, content, fname
      end
    end

    # INSTANCE

    def render *keys
      if keys.any?
        _log_render_in keys
        renderer.render keys, binding, self
      elsif renderer.stack.any?
        renderer.stack.pop
      else
        raise EmptyRenderStack, EMPTY_RENDER_STACK_MESSAGE, caller
      end
    end

    def _log_render_in keys
      if renderer.stack.any?
        log "render ↓ #{keys.join ", "}"
      else
        log "render #{"→ " * keys.size}#{keys.join ", "}"
      end
    end
  end

  extension do
    # CLASS

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

    def render keys, the_binding, receiver
      erbs = find_erbs_for(keys).to_a

      erbs.reverse.each do |key, erb|
        t = Time.now
        s = erb.result the_binding, receiver
        _log_render_out key, s.length, t.diff
        s = wrap_comment_tags s, erb if App.mode == :code && erb.tags?
        stack.push s
      end

      stack.pop
    end

    def find_erbs_for keys
      ret = {}
      keys.each do |key|
        key = "#{key}.erb"

        controller = solder.class.controller_ancestors.
          find { |controller| controller.renderers.has_key? key }

        if controller
          ret[key] = controller.renderers[key]
        else
          raise_renderer_not_found key
        end
      end

      ret
    end

    def raise_renderer_not_found key
      raise RendererNotFound,  %|Failed to find ERuby #{key}
Failed to find ERuby #{"#{key}".red} in #{solder.class}.render_paths
#{solder.render_paths.map { |s| "  #{s}/#{"#{key}".red}" }.join}|
    end

    def _log_render_out key, length, t
      if stack.any?
        log "render #{"↑ #{key}".ljust_blanks 20} with #{length.to_s.rjust_blanks 4} characters in #{t}s"
      else
        log "render #{"← #{key}".ljust_blanks 20} with #{length.to_s.rjust_blanks 4} characters in #{t}s"
      end
    end

    def wrap_comment_tags s, erb
      "<!-- #{erb.filename.split("/").last}:#{erb.lineno} -->\n#{s}\n<!-- #{erb.filename.split("/").last} -->"
    end

  end
end
