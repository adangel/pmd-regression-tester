require 'nokogiri'
require_relative '../pmd_report_detail'

module PmdTester
  # Building difference between two pmd xml files
  class DiffBuilder
    # The schema of pmd xml report refers to
    # http://pmd.sourceforge.net/report_2_0_0.xsd
    def build(base_report, patch_report, base_info, patch_info)
      # Serving for 'single' mode,
      # if value of `base_report` is nil then `base_doc` is empty
      base_doc = if !base_report.nil?
                   Nokogiri::XML(File.read(base_report)).remove_namespaces!
                 else
                   Nokogiri::XML('')
                 end

      patch_doc = Nokogiri::XML(File.read(patch_report)).remove_namespaces!

      report_diff = ReportDiff.new
      build_violation_diffs(base_doc, patch_doc, report_diff)
      build_error_diffs(base_doc, patch_doc, report_diff)
      build_detail_diffs(base_info, patch_info, report_diff)

      report_diff
    end

    def build_detail_diffs(base_info, patch_info, report_diff)
      base_details = PmdReportDetail.new
      base_details.load(base_info) unless base_info.nil?
      patch_details = PmdReportDetail.new
      patch_details.load(patch_info) unless patch_info.nil?

      report_diff.base_execution_time = base_details.format_execution_time
      report_diff.patch_execution_time = patch_details.format_execution_time
      report_diff.diff_execution_time =
        PmdReportDetail.convert_seconds(base_details.execution_time -
                                          patch_details.execution_time)

      report_diff.base_timestamp = base_details.timestamp
      report_diff.patch_timestamp = patch_details.timestamp
    end

    def build_diffs(base_hash, patch_hash)
      diffs = base_hash.merge(patch_hash) do |_key, base_value, patch_value|
        (base_value | patch_value) - (base_value & patch_value)
      end

      diffs.delete_if do |_key, value|
        value.empty?
      end
    end

    def build_violation_diffs(base_doc, patch_doc, report_diff)
      base_hash, base_violations_size = get_violations_hash(base_doc, 'base')
      report_diff.base_violations_size = base_violations_size
      patch_hash, patch_violations_size = get_violations_hash(patch_doc, 'patch')
      report_diff.patch_violations_size = patch_violations_size

      violation_diffs = build_diffs(base_hash, patch_hash)
      violation_diffs_size = get_diffs_size(violation_diffs)
      report_diff.violation_diffs = violation_diffs
      report_diff.violation_diffs_size = violation_diffs_size
    end

    def get_diffs_size(diffs_hash)
      size = 0
      diffs_hash.keys.each do |key|
        size += diffs_hash[key].size
      end
      size
    end

    def get_violations_hash(doc, branch)
      # key:filename as String => value:PmdViolation Array
      violations_hash = {}
      violations_size = 0

      doc.xpath('//file').each do |file|
        filename, violations = get_violations_in_file(file, branch)
        violations_size += violations.size
        violations_hash.store(filename, violations)
      end
      [violations_hash, violations_size]
    end

    def get_violations_in_file(file, branch)
      # The shcema of 'file' node:
      #  <xs:complexType name="file">
      #    <xs:sequence>
      #      <xs:element name="violation" type="violation" minOccurs="1" maxOccurs="unbounded" />
      #      </xs:sequence>
      #    <xs:attribute name="name" type="xs:string" use="required"/>
      #  </xs:complexType>

      filename = file['name']
      violations = []
      file.xpath('violation').each do |violation|
        violations.push(PmdViolation.new(violation, branch))
      end
      [filename, violations]
    end

    def build_error_diffs(base_doc, patch_doc, report_diff)
      base_hash, base_errors_size = get_errors_hash(base_doc, 'base')
      report_diff.base_errors_size = base_errors_size
      patch_hash, patch_errors_size = get_errors_hash(patch_doc, 'patch')
      report_diff.patch_errors_size = patch_errors_size

      error_diffs = build_diffs(base_hash, patch_hash)
      error_diffs_size = get_diffs_size(error_diffs)
      report_diff.error_diffs = error_diffs
      report_diff.error_diffs_size = error_diffs_size
    end

    def get_errors_hash(doc, branch)
      # key:filename as String => value:PmdError Array
      errors_hash = {}
      errors_size = 0

      doc.xpath('//error').each do |error|
        filename = error['filename']
        pmd_error = PmdError.new(error, branch)
        if errors_hash.key?(filename)
          errors_hash[filename].push(pmd_error)
        else
          errors_hash.store(filename, [pmd_error])
        end
        errors_size += 1
      end
      [errors_hash, errors_size]
    end
  end

  # This class represents a 'error' element of Pmd xml report
  # and which Pmd branch the 'error' is from
  class PmdError
    # The pmd branch type, 'base' or 'patch'
    attr_reader :branch

    # The schema of 'error' node:
    #   <xs:complexType name="error">
    #     <xs:simpleContent>
    #       <xs:extension base="xs:string">
    #         <xs:attribute name="filename" type="xs:string" use="required"/>
    #         <xs:attribute name="msg" type="xs:string" use="required"/>
    #       </xs:extension>
    #     </xs:simpleContent>
    #  </xs:complexType>
    attr_reader :error

    def initialize(error, branch)
      @error = error
      @branch = branch
    end

    def get_filename
      @error['filename']
    end

    def get_msg
      @error['msg']
    end

    def get_details
      @error.text
    end

    def eql?(other)
      get_filename.eql?(other.get_filename) && get_msg.eql?(other.get_msg) &&
        get_details.eql?(other.get_details)
    end

    def hash
      [get_filename, get_msg].hash
    end
  end

  # This class represents a 'violation' of Pmd xml report
  # and which pmd branch the 'violation' is from
  class PmdViolation
    # The pmd branch type, 'base' or 'patch'
    attr_reader :branch

    # The schema of 'violation' node:
    # <xs:complexType name="violation">
    #   <xs:simpleContent>
    #     <xs:extension base="xs:string">
    #       <xs:attribute name="beginline" type="xs:integer" use="required" />
    #       <xs:attribute name="endline" type="xs:integer" use="required" />
    #       <xs:attribute name="begincolumn" type="xs:integer" use="required" />
    #       <xs:attribute name="endcolumn" type="xs:integer" use="required" />
    #       <xs:attribute name="rule" type="xs:string" use="required" />
    #       <xs:attribute name="ruleset" type="xs:string" use="required" />
    #       <xs:attribute name="package" type="xs:string" use="optional" />
    #       <xs:attribute name="class" type="xs:string" use="optional" />
    #       <xs:attribute name="method" type="xs:string" use="optional" />
    #       <xs:attribute name="variable" type="xs:string" use="optional" />
    #       <xs:attribute name="externalInfoUrl" type="xs:string" use="optional" />
    #       <xs:attribute name="priority" type="xs:string" use="required" />
    #     </xs:extension>
    #   </xs:simpleContent>
    # </xs:complexType>

    attr_reader :violation

    def initialize(violation, branch)
      @violation = violation
      @branch = branch
    end

    def eql?(other)
      @violation['beginline'].eql?(other.violation['beginline']) &&
        @violation['rule'].eql?(other.violation['rule']) &&
        @violation.text.eql?(other.violation.text)
    end

    def hash
      [@violation['beginline'], @violation['rule'], @violation.content].hash
    end
  end

  # This class represents all the diff report information,
  # including the summary information of the original pmd reports,
  # as well as the specific information of the diff report.
  class ReportDiff
    attr_accessor :base_violations_size
    attr_accessor :patch_violations_size
    attr_accessor :violation_diffs_size

    attr_accessor :base_errors_size
    attr_accessor :patch_errors_size
    attr_accessor :error_diffs_size

    attr_accessor :base_execution_time
    attr_accessor :patch_execution_time
    attr_accessor :diff_execution_time

    attr_accessor :base_timestamp
    attr_accessor :patch_timestamp

    attr_accessor :violation_diffs
    attr_accessor :error_diffs

    def initialize
      @base_violations_size = 0
      @patch_violations_size = 0
      @violation_diffs_size = 0

      @base_errors_size = 0
      @patch_errors_size = 0
      @error_diffs_size = 0

      @base_execution_time = 0
      @patch_execution_time = 0
      @diff_execution_time = 0

      @base_timestamp = ''
      @patch_timestamp = ''

      @violation_diffs = {}
      @error_diffs = {}
    end

    def diffs_exist?
      !error_diffs_size.zero? || !violation_diffs_size.zero?
    end
  end
end
