class NetSystem
  class NetBoxTest < Liza::BoxTest

    test :subject_class do
      assert subject_class == NetSystem::NetBox
    end

    test :settings do
      assert subject_class.log_level == :normal
      assert subject_class.log_color == :red
    end

    test :panels do
      assert subject_class.clients.is_a? ClientPanel
      assert subject_class.databases.is_a? DatabasePanel
    end

  end
end
