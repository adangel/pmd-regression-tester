# frozen_string_literal: true

require 'nokogiri'
require 'set'

module PmdTester
  # This class is responsible for generation dynamic configuration
  # according to the difference between base and patch branch of Pmd.
  # Attention: we only consider java rulesets now.
  class RuleSetBuilder
    include PmdTester
    ALL_CATEGORIES = Set['bestpractices.xml', 'codestyle.xml', 'design.xml', 'documentation.xml',
                         'errorprone.xml', 'multithreading.xml', 'performance.xml',
                         'security.xml'].freeze
    PATH_TO_PMD_JAVA_BASED_RULES =
      'pmd-java/src/main/java/net/sourceforge/pmd/lang/java/rule'
    PATH_TO_PMD_XPATH_BASED_RULES = 'pmd-java/src/main/resources/category/java'
    PATH_TO_ALL_JAVA_RULES =
      ResourceLocator.locate('config/all-java.xml')
    PATH_TO_DYNAMIC_CONFIG = 'target/dynamic-config.xml'
    NO_JAVA_RULES_CHANGED_MESSAGE = 'No java rules have been changed!'

    def initialize(options)
      @options = options
    end

    def build
      filenames = diff_filenames
      rule_refs = get_rule_refs(filenames)
      output_filter_set(rule_refs)
      build_config_file(rule_refs)
      logger.debug "Dynamic configuration: #{[rule_refs]}"
      rule_refs
    end

    def calculate_filter_set
      output_filter_set(ALL_CATEGORIES)
    end

    def output_filter_set(rule_refs)
      if rule_refs == ALL_CATEGORIES
        if @options.mode == Options::ONLINE
          @options.filter_set = Set[]
          doc = File.open(@options.patch_config) { |f| Nokogiri::XML(f) }
          rules = doc.css('ruleset rule')
          rules.each do |r|
            ref = r.attributes['ref'].content
            ref.delete_prefix!('category/java/')
            @options.filter_set.add(ref)
          end

          logger.debug "Using filter based on patch config #{@options.patch_config}: " \
                       "#{@options.filter_set}"
        else
          # if `rule_refs` contains all categories, then no need to filter the baseline
          logger.debug 'No filter when comparing patch to baseline'
          @options.filter_set = nil
        end
      else
        logger.debug "Filter is now #{rule_refs}"
        @options.filter_set = rule_refs
      end
    end

    def diff_filenames
      filenames = nil
      Dir.chdir(@options.local_git_repo) do
        base = @options.base_branch
        patch = @options.patch_branch
        # We only need to support git here, since PMD's repo is using git.
        diff_cmd = "git diff --name-only #{base}..#{patch} -- pmd-core/src/main pmd-java/src/main"
        filenames = Cmd.execute(diff_cmd)
      end
      filenames.split("\n")
    end

    def get_rule_refs(filenames)
      categories, rules = determine_categories_rules(filenames)
      logger.debug "Categories: #{categories}"
      logger.debug "Rules: #{rules}"

      # filter out all individual rules that are already covered by a complete category
      categories.each do |cat|
        rules.delete_if { |e| e.start_with?(cat) }
      end

      refs = Set[]
      refs.merge(categories)
      refs.merge(rules)
      refs
    end

    def determine_categories_rules(filenames)
      categories = Set[]
      rules = Set[]
      filenames.each do |filename|
        match_data = check_single_filename(filename)

        unless match_data.nil?
          if match_data.size == 2
            categories.add("#{match_data[1]}.xml")
          else
            rules.add("#{match_data[1]}.xml/#{match_data[2]}")
          end
        end

        next unless match_data.nil?

        logger.debug "Change doesn't match specific rule/category - enable all rules"
        categories = ALL_CATEGORIES
        rules.clear
        break
      end
      [categories, rules]
    end

    def check_single_filename(filename)
      logger.debug "Checking #{filename}"
      match_data = %r{#{PATH_TO_PMD_JAVA_BASED_RULES}/([^/]+)/([^/]+)Rule.java}.match(filename)
      match_data = %r{#{PATH_TO_PMD_XPATH_BASED_RULES}/([^/]+).xml}.match(filename) if match_data.nil?
      logger.debug "Matches: #{match_data.inspect}"
      match_data
    end

    def build_config_file(rule_refs)
      if rule_refs.empty?
        logger.info NO_JAVA_RULES_CHANGED_MESSAGE
        return
      end

      if rule_refs == ALL_CATEGORIES
        logger.debug 'All rules are used. Not generating a dynamic ruleset.'
        logger.debug "Using the configured/default ruleset base_config=#{@options.base_config} "\
                     "patch_config=#{@options.patch_config}"
        return
      end

      write_dynamic_file(rule_refs)
    end

    def write_dynamic_file(rule_refs)
      logger.debug "Generating dynamic configuration for: #{[rule_refs]}"
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.ruleset('xmlns' => 'http://pmd.sourceforge.net/ruleset/2.0.0',
                    'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                    'xsi:schemaLocation' => 'http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd',
                    'name' => 'Dynamic PmdTester Ruleset') do
          xml.description 'The ruleset generated by PmdTester dynamically'
          rule_refs.each do |entry|
            xml.rule('ref' => "category/java/#{entry}")
          end
        end
      end
      doc = builder.to_xml(indent: 4, encoding: 'UTF-8')
      File.open(PATH_TO_DYNAMIC_CONFIG, 'w') do |x|
        x << doc.gsub(/\n\s+\n/, "\n")
      end
      @options.base_config = PATH_TO_DYNAMIC_CONFIG
      @options.patch_config = PATH_TO_DYNAMIC_CONFIG
    end
  end
end
