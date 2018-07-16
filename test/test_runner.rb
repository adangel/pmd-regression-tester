# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'
require_relative '../lib/pmdtester/runner'

# Unit test class for PmdTester::Runner
class TestRunner < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  include PmdTester

  def test_single_mode
    PmdReportBuilder.any_instance.stubs(:build)
                    .returns(PmdBranchDetail.new('test_branch')).once
    FileUtils.mkdir_p('target/reports/test_branch')
    DiffBuilder.any_instance.stubs(:build).twice
    DiffReportBuilder.any_instance.stubs(:build).twice
    SummaryReportBuilder.any_instance.stubs(:build).once

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml -m single]
    Runner.new(argv).run
  end

  def test_local_mode
    PmdReportBuilder.any_instance.stubs(:build).twice
    DiffBuilder.any_instance.stubs(:build).twice
    DiffReportBuilder.any_instance.stubs(:build).twice
    SummaryReportBuilder.any_instance.stubs(:build).once

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml]
    Runner.new(argv).run
  end
end