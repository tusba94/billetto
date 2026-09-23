require "test_helper"

class ImportBillettoEventsJobTest < ActiveJob::TestCase
  class TestImportService
    @@called = false

    def self.called?
      @@called
    end

    def self.reset
      @@called = false
    end

    def call
      @@called = true
    end
  end

  test "calls the import service" do
    TestImportService.reset

    original_service = ImportBillettoEvents

    Object.send(:remove_const, :ImportBillettoEvents)
    Object.const_set(:ImportBillettoEvents, TestImportService)

    begin
      ImportBillettoEventsJob.perform_now

      assert TestImportService.called?
    ensure
      Object.send(:remove_const, :ImportBillettoEvents)
      Object.const_set(:ImportBillettoEvents, original_service)
    end
  end
end