# frozen_string_literal: true

# https://docs.ruby-lang.org/en/3.1/ERB.html
# https://docs.ruby-lang.org/en/3.1/ERB/DefMethod.html
# https://docs.ruby-lang.org/en/3.1/ERB/Util.html

Liza::ERB = Liza::Erb = Class.new ERB
class Liza::Erb
  class Error < StandardError; end
  class BuildError < Error; end
  class RunTimeError < Error; end

  alias c class

  def self.from_file key, content, filename, lineno
    erb = Liza::Erb.new key, content, filename, lineno
    erb.type = :file
    erb
  end

  def self.from_folder key, content, filename, lineno = 0
    erb = Liza::Erb.new key, content, filename, lineno
    erb.type = :folder
    erb
  end

  attr_accessor :type
  attr_reader :key, :format

  def initialize key, content, filename, lineno
    segments = key.split("/").last.split(".")
    raise BuildError, "key #{key} must be formatted as <name>.<format>.erb" unless segments.count == 3
    format = segments[1]
    raise BuildError, "key #{key} must be formatted as <name>.<format>.erb" unless segments[2] == "erb"
    raise BuildError, "key #{key} has an invalid format :#{format}" unless format.gsub(/[^a-z]/, "") == format

    # %  enables Ruby code processing for lines beginning with %
    # <> omit newline for lines starting with <% and ending in %>
    # >  omit newline for lines ending in %>
    # -  omit blank lines ending in -%>

    super content, :trim_mode => "<>-"
    @key, @format, self.filename, self.lineno = key, format, filename, lineno
  end

  TAG_FORMATS = %w|xml html|

  def tags?
    TAG_FORMATS.include? format
  end

  def file?
    type == :file
  end

  def folder?
    type == :folder
  end

  def result the_binding, receiver=:unset
    super the_binding
  rescue NameError => e
    # binding.irb
    raise unless e.receiver == receiver
    message = "ERB template for a #{e.receiver.class} instance could not find method '#{e.name}'"
    # puts message
    # puts e.backtrace[0]
    raise Liza::Erb::RunTimeError, message, e.backtrace[0]
  # rescue StandardError => e
  #   raise Liza::Erb::RunTimeError, e.message, e
  #   puts e.full_message
  #   puts "backtrace:"
  #   puts e.backtrace
  #   raise
  end
end
