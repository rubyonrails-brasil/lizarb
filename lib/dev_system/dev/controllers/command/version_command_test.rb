class DevSystem
  class VersionCommandTest < CommandTest

    test :subject_class do
      assert subject_class == DevSystem::VersionCommand
    end

    test :settings do
      assert subject_class.log_level == :normal
      assert subject_class.log_color == :green
    end

  end
end
