module Liza
  class Controller < Unit
    part :controller_renderer

    inherited_explicitly_sets_system

    def self.on_connected box_klass, panel
      set :box, box_klass
      set :panel, panel
    end

    def self.box
      get :box
    end

    def self.panel
      get :panel
    end

    def box
      self.class.box
    end

    def panel
      self.class.panel
    end

  end
end
