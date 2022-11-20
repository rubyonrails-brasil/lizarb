class DevSystem
  class TestCommand < Command

    def self.call args
      log :higher, "Called #{self} with args #{args}"

      App.eager_load_all

      now = Time.now
      test_classes = Liza::Test.descendants

      test_classes = _call_sort test_classes

      log "Testing #{test_classes}"
      _call_testing test_classes
      log "Done Testing (#{now.diff}s)"

      puts

      log "Counting #{test_classes.count} Test Classes"
      _call_counting test_classes
      log "Done Counting (#{now.diff}s)"
    end

    def self._call_sort test_classes
      test_classes.sort_by! &:name

      proc_namespaced = proc { |tc| tc.name.include? "::" }
      proc_liza = proc { |tc| tc.name[0..3] == "Liza" }

      tc_app        = test_classes.reject &proc_namespaced
      tc_namespaced = test_classes.select &proc_namespaced

      tc_liza   = tc_namespaced.select &proc_liza
      tc_system = tc_namespaced.reject &proc_liza

      tc_app.sort_by! &:source_location
      tc_liza.sort_by! &:source_location

      [tc_liza, tc_system, tc_app].flatten
    end

    def self._call_testing test_classes
      i, count = 0, test_classes.count
      for test_class in test_classes
        test_class.call i+=1, count
      end
    end

    def self._call_counting test_classes
      puts
      totals = Hash.new { 0 }
      last_namespace = nil
      test_classes.each do |test_class|
        namespace = test_class.first_namespace
        puts if last_namespace != namespace
        last_namespace = namespace

        test_class.totals.each do |k, v|
          totals[k] += v.size
        end
        Liza.log "  #{"#{test_class}.totals".ljust 60} #{test_class.totals.map { |k, v| [k, v.size] }.to_h}"
      end
      puts
      Liza.log "  #{"Total".ljust 60} #{totals}"
      puts
    end

  end
end
