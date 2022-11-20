class Liza::UnitProcedurePartTest < Liza::UnitTest

  test :procedure_scopes_and_returns do
    b = nil

    w =
      procedure "creates a new scope" do
        @a = 1
        b = 2
        c = 3
        assert true

        proceed if true
        raise "did not get here"
      end

    assert assertions > 0
    assert w.nil?

    x =
      procedure "asserts old scope is not accessible" do
        assert instance_variables.include? :@a
        assert local_variables.include? :b
        refute local_variables.include? :c

        assert @a == 1
        assert b == 2

        proceed 100 if true
        raise "did not get here"
      end

    assert x == 100

    y =
      procedure "asserts proceed calls can be lazy" do
        proceed { "slow operation"; 200 } if true
        raise "did not get here"
      end

    assert y == 200
  end

  test :procedure_rescue_and_ensure do
    procedure "assert ensure works" do
      @a = 1
    ensure
      @a = 2
    end

    assert @a == 2

    procedure "assert rescue works" do
      @a = [1]
      raise "a runtime error!"
    rescue RuntimeError
      @a << 2
    ensure
      @a << 3
    end

    assert @a == [1, 2, 3]
  end

end
