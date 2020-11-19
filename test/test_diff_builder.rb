# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::DiffBuilder
class TestDiffBuilder < Test::Unit::TestCase
  include PmdTester
  BASE_REPORT_INFO_PATH = 'test/resources/diff_builder/base_report_info.json'
  PATCH_REPORT_INFO_PATH = 'test/resources/diff_builder/patch_report_info.json'

  def setup
    `rake clean`
  end

  def test_violation_diffs
    diff_builder = DiffBuilder.new
    base_report_path = 'test/resources/diff_builder/test_violation_diffs_base.xml'
    patch_report_path = 'test/resources/diff_builder/test_violation_diffs_patch.xml'
    diffs_report = diff_builder.build(base_report_path, patch_report_path,
                                      BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)
    violation_diffs = diffs_report.violation_diffs
    keys = violation_diffs.keys

    assert_empty(diffs_report.error_diffs_by_file)
    assert_empty(diffs_report.configerrors_diffs)
    assert_equal(5, diffs_report.base_violations_size)
    assert_equal(8, diffs_report.patch_violations_size)
    assert_equal(6, diffs_report.violation_diffs_size)

    assert_violations_equal(diffs_report, 1, 4, 1)

    assert_equal('Base1.java', keys[0])
    assert_equal('SameFileNameWithDiffViolations.java', keys[1])
    assert_equal(2, violation_diffs[keys[1]].size)
    assert_equal('Patch1.java', keys[2])
    assert_equal('Patch2.java', keys[3])
    assert_equal('Patch3.java', keys[4])

    assert_equal('00:00:56', diffs_report.diff_execution_time)
    assert_equal(false, diffs_report.introduce_new_errors?)
  end

  def test_error_diffs
    diff_builder = DiffBuilder.new
    base_report_path = 'test/resources/diff_builder/test_error_diffs_base.xml'
    patch_report_path = 'test/resources/diff_builder/test_error_diffs_patch.xml'
    diffs_report = diff_builder.build(base_report_path, patch_report_path,
                                      BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)
    error_diffs = diffs_report.error_diffs_by_file
    keys = error_diffs.keys

    assert_empty(diffs_report.violation_diffs)
    assert_empty(diffs_report.configerrors_diffs)
    assert_equal(4, diffs_report.base_errors_size)
    assert_equal(3, diffs_report.patch_errors_size)
    assert_equal(5, diffs_report.error_diffs_size)
    assert_equal(3, diffs_report.removed_errors_size)
    assert_equal(2, diffs_report.new_errors_size)
    assert_equal(3, keys.size)
    assert_equal('Base1.java', keys[0])
    assert_equal(2, error_diffs['Base1.java'].size)
    assert_equal('Both2.java', keys[1])
    assert_equal(2, error_diffs['Both2.java'].size)
    assert_equal('Patch1.java', keys[2])
    assert_equal(true, diffs_report.introduce_new_errors?)
  end

  def test_configerrors_diffs
    diff_builder = DiffBuilder.new
    base_report_path = 'test/resources/diff_builder/test_configerrors_diffs_base.xml'
    patch_report_path = 'test/resources/diff_builder/test_configerrors_diffs_patch.xml'
    diffs_report = diff_builder.build(base_report_path, patch_report_path,
                                      BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)
    configerrors_diffs = diffs_report.configerrors_diffs
    keys = configerrors_diffs.keys

    assert_empty(diffs_report.violation_diffs_by_file)
    assert_empty(diffs_report.error_diffs_by_file)
    assert_equal(4, diffs_report.base_configerrors_size)
    assert_equal(3, diffs_report.patch_configerrors_size)
    assert_equal(5, diffs_report.configerrors_diffs_size)
    assert_equal(3, diffs_report.removed_configerrors_size)
    assert_equal(2, diffs_report.new_configerrors_size)
    assert_equal(3, keys.size)
    assert_equal('RuleBase1', keys[0])
    assert_equal(2, configerrors_diffs['RuleBase1'].size)
    assert_equal('RuleBoth2', keys[1])
    assert_equal(2, configerrors_diffs['RuleBoth2'].size)
    assert_equal('RulePatch1', keys[2])
    assert_equal(true, diffs_report.introduce_new_errors?)
  end

  private

  def assert_violations_equal(diffs_report, removed, added, changed)
    assert_equal(removed, diffs_report.removed_violations_size)
    assert_equal(added, diffs_report.new_violations_size)
    assert_equal(changed, diffs_report.changed_violations_size)
  end
end
