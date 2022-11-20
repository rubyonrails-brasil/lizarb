# frozen_string_literal: true

class Module

  # /path/to/liza.rb
  def source_location
    Object.const_source_location name
  end

  # /path/to/liza
  def source_location_radical
    source_location[0][0..-4]
  rescue
    nil
  end

end
