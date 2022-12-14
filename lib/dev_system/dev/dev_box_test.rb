class DevSystem
  class DevBoxTest < Liza::BoxTest

    test :subject_class do
      assert subject_class == DevSystem::DevBox
    end

    test :settings do
      assert subject_class.log_level == :normal
      assert subject_class.log_color == :green
    end

    test :panels do
      assert subject_class.commands.is_a? CommandPanel
      assert subject_class.logs.is_a? LogPanel
    end

  end
end
