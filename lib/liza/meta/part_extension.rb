module Liza
  class PartExtension
    def self.solder
      @solder ||=
        if first_namespace == "Liza"
          Liza.const_get last_namespace[0..-12]
        else
          Object.const_get name[0..-12]
        end
    end

    def initialize solder
      @solder = solder
    end

    attr_reader :solder
  end
end
