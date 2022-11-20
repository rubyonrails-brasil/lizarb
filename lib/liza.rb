# frozen_string_literal: true

module Liza
  class Error < StandardError; end
  class ConstNotFound < Error; end

  #

  module_function

  def log s
    puts s.bold
  end

  #

  # Checks Object, each system, then Liza for Liza::Unit classes
  def const name
    name = name.to_s.camelize.to_sym

    k = const_check_object name
    return k if k

    k = const_check_systems name
    return k if k

    k = const_get name
    return k if k

    nil
  rescue NameError
    raise ConstNotFound, name
  end

  # Checks each system, then Liza for Liza::Unit classes
  def const_missing name
    k = const_check_systems name
    return k if k

    super
  end

  def const_check_object name
    return if not Object.const_defined? name
    kk = Object.const_get name
    return kk if is_unit? kk

    nil
  end

  def const_check_systems name
    App.systems.frozen? or return nil

    for k in App.systems.values.reverse
      next if not k.const_defined? name.to_sym
      kk = k.const(name) if k.constants.include? name
      return kk if is_unit? kk
    end

    nil
  end

  def is_unit? kk
    kk && kk < Liza::Unit
  end

end
