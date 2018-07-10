# frozen_string_literal: true

require 'logger'
require_relative './builders/diff_builder.rb'
require_relative './builders/diff_report_builder.rb'
require_relative './builders/rule_set_builder'
require_relative './builders/summary_report_builder.rb'
require_relative './builders/pmd_report_builder.rb'
require_relative './parsers/options'
require_relative './parsers/projects_parser'
require_relative './pmd_branch_detail'

module PmdTester
  def logger
    PmdTester.logger
  end

  # Global, memoized, lazy initialized instance of a logger
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  # The Runner is a class responsible of organizing all PmdTester modules
  # and running the PmdTester
  class Runner
    include PmdTester
    LOCAL = 'local'
    ONLINE = 'online'
    SINGLE = 'single'
    def initialize(argv)
      @options = Options.new(argv)
      logger.level = @options.debug_flag ? Logger::DEBUG : Logger::INFO
    end

    def run
      case @options.mode
      when LOCAL
        run_local_mode
      when ONLINE
        run_online_mode
      when SINGLE
        run_single_mode
      else
        logger.error "The mode '#{@options.mode}' is invalid!"
        exit(1)
      end
    end

    def run_local_mode
      logger.info "Mode: #{@options.mode}"
      RuleSetBuilder.new(@options).build if @options.auto_config_flag

      check_option(LOCAL, 'base branch name', @options.base_branch)
      check_option(LOCAL, 'base branch config path', @options.base_config)
      check_option(LOCAL, 'patch branch name', @options.patch_branch)
      check_option(LOCAL, 'patch branch config path', @options.patch_config)
      check_option(LOCAL, 'list of projects file path', @options.project_list)

      get_projects(@options.project_list) unless @options.nil?
      PmdReportBuilder
        .new(@options.base_config, @projects, @options.local_git_repo, @options.base_branch)
        .build
      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      build_html_reports
    end

    def run_online_mode
      logger.info "Mode: #{@options.mode}"
      check_option(ONLINE, 'base branch name', @options.base_branch)
      check_option(ONLINE, 'patch branch name', @options.patch_branch)

      baseline_path = download_baseline(@options.base_branch)

      if @options.auto_config_flag
        RuleSetBuilder.new(@options).build
      else
        # patch branch build pmd reports with same configuration as base branch
        @options.patch_config = "#{baseline_path}/config.xml"
      end

      # patch branch build pmd report with same list of projects as base branch
      project_list = "#{baseline_path}/project-list.xml"
      get_projects(project_list)

      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      build_html_reports
    end

    def download_baseline(branch_name)
      branch_filename = PmdBranchDetail.branch_filename(branch_name)
      zip_filename = "#{branch_filename}-baseline.zip"
      target_path = 'target/reports'
      FileUtils.mkdir_p(target_path) unless File.directory?(target_path)

      url = get_baseline_url(zip_filename)
      wget_cmd = "wget #{url}"
      unzip_cmd = "unzip -qo #{zip_filename}"

      Dir.chdir(target_path) do
        Cmd.execute(wget_cmd) unless File.exist?(zip_filename)
        Cmd.execute(unzip_cmd)
      end

      "#{target_path}/#{branch_filename}"
    end

    def get_baseline_url(zip_filename)
      "https://sourceforge.net/projects/pmd/files/pmd-regression-tester/#{zip_filename}"
    end

    def run_single_mode
      logger.info "Mode: #{@options.mode}"
      check_option(SINGLE, 'patch branch name', @options.patch_branch)
      check_option(SINGLE, 'patch branch config path', @options.patch_config)
      check_option(SINGLE, 'list of projects file path', @options.project_list)

      get_projects(@options.project_list) unless @options.nil?
      branch_details = PmdReportBuilder
                       .new(@options.patch_config, @projects,
                            @options.local_git_repo, @options.patch_branch)
                       .build
      # copy list of projects file to the patch baseline
      FileUtils.cp(@options.project_list, branch_details.target_branch_project_list_path)

      build_html_reports unless @options.html_flag
    end

    def build_html_reports
      build_diff_html_reports
      SummaryReportBuilder.new.build(@projects, @options.base_branch, @options.patch_branch)
    end

    def build_diff_html_reports
      @projects.each do |project|
        logger.info "Preparing report for #{project.name}"
        report_diffs = DiffBuilder.new.build(project.get_pmd_report_path(@options.base_branch),
                                             project.get_pmd_report_path(@options.patch_branch),
                                             project.get_report_info_path(@options.base_branch),
                                             project.get_report_info_path(@options.patch_branch),
                                             @options.filter_set)
        project.report_diff = report_diffs
        DiffReportBuilder.new.build(project)
      end
      logger.info 'Built all difference reports successfully!'
    end

    def check_option(mode, option_name, option)
      if option.nil?
        logger.error "In #{mode} mode, #{option_name} is required!"
        exit 1
      else
        logger.info "#{option_name}: #{option}"
      end
    end

    def get_projects(file_path)
      @projects = ProjectsParser.new.parse(file_path)
    end
  end
end
