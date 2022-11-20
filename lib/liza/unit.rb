module Liza
  class Unit

    # PARTS

    def self.part key, system: nil
      App.connect_part self, key, system
    end

    part :unit_procedure

    # SETTINGS

    def self.settings
      @settings ||= {}
    end

    def self.get key
      return settings[key] if settings.has_key? key

      found = nil

      for klass in ancestors
        break unless klass.respond_to? :settings

        if klass.settings.has_key? key
          found = klass.settings[key]

          break
        end
      end

      found = settings[key] = found.dup if found.is_a? Enumerable

      found
    end

    def self.set key, value
      settings[key] = value
      value
    end

    def self.add list, key = nil, value
      if key
        fetch(list) { Hash.new }[key] = value
      else
        fetch(list) { Set.new } << value
      end
    end

    def self.fetch key, &block
      x = get key
      x ||= set key, instance_eval(&block)
      x
    end

    def settings
      @settings ||= {}
    end

    def get key
      return settings[key] if settings.has_key? key

      self.class.get key
    end

    def set key, value
      settings[key] = value
    end

    def add list, key = nil, value
      if key
        fetch(list) { Hash.new }[key] = value
      else
        fetch(list) { Set.new } << value
      end
    end

    def fetch key, &block
      x = get key
      x ||= set key, eval(&block)
      x
    end

    # LOG

    LOG_LEVELS = {
      :higher => 2,
      :high   => 1,
      :normal => 0,
      :low    => -1,
      :lower  => -2,
    }

    set :log_level, :normal
    set :log_color, :white

    #

    LOG_JUST = 40

    def self.log log_level = :normal, string
      raise "invalid log_level `#{log_level}`" unless LOG_LEVELS.keys.include? log_level
      return unless log_level? log_level

      source = (self.is_a? Class) ? self : self.class
      source = source.to_s.ljust(LOG_JUST).bold.colorize(source.log_color)

      string = "#{source} #{string}"

      DevBox.logs.call string
    end

    def self.log_level
      get(:log_level) || :normal
    end

    def self.log_level? log_level = :normal
      # TODO
      true
    end

    def self.log_color
      (get(:system) || self).get :log_color
    end

    def self.log?(log_level = :normal)= log_level? log_level
    def log(...)= self.class.log(...)
    def log_level(...)= self.class.log_level(...)
    def log?(...)= self.class.log?(...)
    def log_level?(...)= self.class.log_level?(...)
    def log_color(...)= self.class.log_color(...)

    # SYSTEM

    def self.inherited_explicitly_sets_system

      def self.inherited sub
        super

        return unless sub.name.to_s.include? "::"

        system = Object.const_get sub.first_namespace

        sub.set :system, system
      end

    end

  end
end
