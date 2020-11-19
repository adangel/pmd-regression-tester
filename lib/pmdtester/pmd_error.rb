# frozen_string_literal: true

module PmdTester

  # This class represents a 'error' element of Pmd xml report
  # and which Pmd branch the 'error' is from
  class PmdError
    include PmdTester
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
    attr_reader :attrs
    attr_accessor :text
    attr_accessor :old_error

    def initialize(attrs, branch)
      @attrs = attrs

      @branch = branch
      @text = ''
      @changed = false
    end

    def filename
      @attrs['filename'] # was already normalized to remove path outside project
    end

    def short_filename
      filename.gsub(%r{([^/]*+/)+}, '')
    end

    def short_message
      @attrs['msg']
    end

    def stack_trace
      @text
    end

    def changed?
      @changed
    end

    def eql?(other)
      filename.eql?(other.filename) &&
        short_message.eql?(other.short_message) &&
        stack_trace.eql?(other.stack_trace)
    end

    def hash
      [filename, stack_trace].hash
    end

    def sort_key
      filename
    end

    def try_merge?(other)
      if branch != BASE &&
         branch != other.branch &&
         filename == other.filename &&
         !changed? # not already changed
        @changed = true
        @old_error = other
        true
      else
        false
      end
    end
  end
end
