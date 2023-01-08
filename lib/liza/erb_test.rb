class Liza::ErbTest < Liza::Test

  test :subject_class do
    assert subject_class == Liza::Erb
  end

  test :valid do
    key = "name.html.erb"
    content = "content <%= value %> content"
    filename = __FILE__
    lineno = 1
    erb = Liza::Erb.new key, content, filename, lineno
    assert erb.is_a? ERB
    assert erb.tags?

    value = "VAL"
    assert erb.result(binding) == "content VAL content"
  end

  test :valid, 2 do
    key = "name.rb.erb"
    content = "content <%= value %> content"
    filename = __FILE__
    lineno = 1
    erb = Liza::Erb.new key, content, filename, lineno
    assert erb.is_a? ERB
    refute erb.tags?

    value = "VAL"
    assert erb.result(binding) == "content VAL content"
  end

  test Liza::Erb::BuildError do
    key = "name.rb.slim"
    content = "content"
    filename = __FILE__
    lineno = 1

    x = nil

    begin
      erb = Liza::Erb.new key, content, filename, lineno
    rescue => e
      x = e
    end
    assert Liza::Erb::BuildError === e
  end

  test Liza::Erb::RunTimeError, "receiver" do
    key = "name.html.erb"
    content = "content <%= this_method %> content"
    filename = __FILE__
    lineno = 1
    erb = Liza::Erb.new key, content, filename, lineno

    assert erb.is_a? ERB
    x = nil

    begin
      erb.result(binding)
    rescue => e
      x = e
    end
    assert NameError === e

    begin
      erb.result(binding, self)
    rescue => e
      x = e
    end
    assert Liza::Erb::RunTimeError === e

  end

  test Liza::Erb::RunTimeError, 2 do
    key = "name.html.erb"
    content = "content <%= 1/0 %>"
    filename = __FILE__
    lineno = 1
    erb = Liza::Erb.new key, content, filename, lineno

    assert erb.is_a? ERB
    x = nil

    begin
      erb.result(binding)
    rescue => e
      x = e
    end
    assert ZeroDivisionError === e

    begin
      erb.result(binding, self)
    rescue => e
      x = e
    end
    assert ZeroDivisionError === e
  end
end
