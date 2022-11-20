class Liza::ControllerRendererPartTest < Liza::Test

  group "class methods" do
    test Liza::Controller do
      controller = Liza::Controller

      assert controller.renderer == Liza::ControllerRendererPart::Extension
      assert controller.renderer.solder == Liza::ControllerRendererPart
      assert controller.render_paths == []
      assert controller.renderers == {}
    end

    test Liza::Controller, :instance do
      controller = Liza::Controller.new

      assert controller.renderer.is_a? Liza::ControllerRendererPart::Extension
      assert controller.renderer.solder == controller
      assert controller.render_paths == []
      refute controller.respond_to? :renderers
    end

    test Liza::Command do
      controller = Liza::Command

      assert controller.renderer == Liza::ControllerRendererPart::Extension
      assert controller.renderer.solder == Liza::ControllerRendererPart
      assert controller.render_paths.count == 1
      assert controller.render_paths[0].end_with? "/lib/dev_system/dev/controllers/command"
      assert controller.renderers == {}
    end

    test Liza::Command, :instance do
      controller = Liza::Command.new

      assert controller.renderer.is_a? Liza::ControllerRendererPart::Extension
      assert controller.renderer.solder == controller
      assert controller.render_paths.count == 1
      assert controller.render_paths[0].end_with? "/lib/dev_system/dev/controllers/command"
      refute controller.respond_to? :renderers
    end
  end

  group "insertion" do
    group "class methods" do
      test :renderer do
        todo "renderer"
      end

      test :controller_ancestors do
        todo "controller_ancestors"
      end

      test :render_paths do
        todo "render_paths"
      end

      test :get_renderers do
        todo "get_renderers"
      end

      test :get_renderers_from_file do
        todo "get_renderers_from_file"
      end

      test :get_renderers_from_folder do
        todo "get_renderers_from_folder"
      end
    end

    group "instance methods" do
      test :renderer do
        todo "renderer"
      end

      test :render do
        todo "render"
      end
    end
  end

  group "extension" do
    group "class methods" do
      test :create_erb do
        todo "create_erb"
      end
    end

    group "instance methods" do
      test :render do
        todo "render"
      end

      test :_render do
        todo "_render"
      end

      test :render_wrap_html do
        todo "render_wrap_html"
      end

      test :erbs_for do
        todo "erbs_for"
      end

      test :erb_for do
        todo "erb_for"
      end
    end
  end

end
