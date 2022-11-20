class Liza::UnitProcedurePart < Liza::Part

  insertion do
    def self.procedure _label, &block
      catch :procedure, &block
    end

    def self.proceed val = nil, &block
      val = yield if val.nil? && block_given?
      throw :procedure, val
    end

    def procedure(_label, &block)= self.class.procedure _label, &block
    def proceed(...)= self.class.proceed(...)
  end

end
