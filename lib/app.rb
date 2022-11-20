module App
  class Error < StandardError; end
  class ModeNotFound < Error; end
  class SystemNotFound < Error; end

  #

  module_function

  def log s
    puts s.bold
  end

  # called from "#{APP_DIR}/app"
  def call argv, &block
    instance_exec &block

    setup_env
    setup_bundle
    setup_liza
    bundle_systems_app Lizarb::APP_DIR

    check_mode!

    puts
    ::DevBox.commands.call argv
    puts
  end

  def root
    Pathname Dir.pwd
  end

  def setup_env
    require "dotenv"
    Dotenv.load "app.#{mode}.env", "app.env"
  end

  def setup_bundle
    require "bundler/setup"
    Bundler.require :default, *@systems.keys
  end

  def setup_liza
    require "liza"

    @loaders << loader = Zeitwerk::Loader.new
    loader.tag = Liza.to_s

    # ORDER MATTERS: IGNORE, COLLAPSE, PUSH
    loader.collapse "#{Liza.source_location_radical}/**/*"
    loader.push_dir "#{Liza.source_location_radical}", namespace: Liza

    loader.enable_reloading
    loader.setup
  end

  def bundle_systems_app app_dir
    @systems.keys.each do |k|
      key = "#{k}_system"

      require_system key
      klass = Object.const_get key.camelize

      @systems[k] = klass
    end

    @loaders << loader = Zeitwerk::Loader.new

    @systems.each do |k, klass|
      # ORDER MATTERS: IGNORE, COLLAPSE, PUSH
      loader.collapse "#{klass.source_location_radical}/**/*"
      loader.push_dir "#{klass.source_location_radical}", namespace: klass
    end

    # ORDER MATTERS: IGNORE, COLLAPSE, PUSH
    loader.collapse "#{app_dir}/app/**/*"
    loader.push_dir "#{app_dir}/app" if Dir.exist? "#{app_dir}/app"

    loader.enable_reloading
    loader.setup

    @systems.each do |k, klass|
      connect_system k, klass
    end

    @systems.freeze
  end

  # loaders

  @loaders = []
  @mutex = Mutex.new

  def reload &block
    @mutex.synchronize do
      @loaders.map &:reload
      yield if block_given?
    end

    true
  end

  def eager_load_all
    Zeitwerk::Loader.eager_load_all
  end

  # mode

  @modes = [:code]
  ENV["LIZA_MODE"] ||= @modes.first.to_s
  @mode = ENV["LIZA_MODE"].to_sym

  def mode mode = nil
    return @mode if mode.nil?
    @modes << mode.to_sym
  end

  def check_mode!
    return if @modes.include? @mode
    raise ModeNotFound, "LIZA_MODE `#{@mode}` not found in #{@modes}", []
  end

  # systems

  @systems = {}

  def system key
    raise "locked" if @locked
    @systems[key] = nil
  end

  def systems
    @systems
  end

  def self.require_system key
    require key
  rescue LoadError => e
    def e.backtrace; []; end
    raise SystemNotFound, "FILE #{key}.rb not found on $LOAD_PATH", []
  end

  # parts

  def connect_part part_klass, key, system
    klass = if system.nil?
              Liza.const "#{key}_part"
            else
              Liza.const("#{system}_system")
                  .const "#{key}_part"
            end

    log "CONNECTING PART #{part_klass.to_s.rjust 25}.part :#{key}" if $VERBOSE

    if klass.insertion
      part_klass.class_exec &klass.insertion
    end

    if klass.extension
      klass.const_set :Extension, Class.new(Liza::PartExtension)
      klass::Extension.class_exec &klass.extension
    end
  end

  # systems

  def connect_system key, system_klass
    t = Time.now

    color_system_klass = system_klass.to_s.colorize system_klass.log_color
    color_key = key.to_s.colorize system_klass.log_color

    registrar_index = 0
    system_klass.registrar.each do |string, target_block|
      reg_type, _sep, reg_target = string.to_s.lpartition "_"

      registrar_index += 1

      target_klass = Liza.const reg_target

      if reg_type == "insertion"
        target_klass.class_exec &target_block
      else
        raise "TODO: decide and implement system extension"
      end

      log "CONNECTING SYSTEM PART          #{color_system_klass}.#{reg_type} #{target_klass}"

    end
    log "CONNECTING SYSTEM - #{t.diff}s for #{color_system_klass} to connect to #{registrar_index} system parts"
  end

end
