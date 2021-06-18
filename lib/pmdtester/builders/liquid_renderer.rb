# frozen_string_literal: true

require 'liquid'
require 'json'

module PmdTester
  # A module to include in classes that use a Liquid template
  # to generate content.
  module LiquidRenderer
    include PmdTester

    def render_liquid(template_path, env)
      to_render = File.read(ResourceLocator.resource(template_path))
      includes = Liquid::LocalFileSystem.new(ResourceLocator.resource('_includes'), '%s.html')
      Liquid::Template.file_system = includes
      template = Liquid::Template.parse(to_render, error_mode: :strict)
      template.render!(env, { strict_variables: true })
    end

    def render_and_write(template_path, target_file, env)
      write_file(target_file, render_liquid(template_path, env))
    end

    def write_file(target_file, contents)
      dir = File.dirname(target_file)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      index = File.new(target_file, 'w')
      index&.puts contents # may be nil when stubbing
      logger&.info "Written #{target_file}"
    ensure
      index&.close
    end

    def copy_resource(dir, to_root)
      src = ResourceLocator.resource(dir)
      dest = "#{to_root}/#{dir}"
      FileUtils.copy_entry(src, dest)
    end
  end

  # Renders the index of a project diff report.
  class LiquidProjectRenderer
    include PmdTester
    include ProjectHasher
    include LiquidRenderer

    def write_project_index(project, root)
      liquid_env = {
        'diff' => report_diff_to_h(project.report_diff),
        'error_diffs' => errors_to_h(project),
        'configerror_diffs' => configerrors_to_h(project),
        'project_name' => project.name
      }

      # Renders index.html using liquid
      write_file("#{root}/index.html", render_liquid('project_diff_report.html', liquid_env))
      # generate array of violations in json
      write_file("#{root}/project_data.js", dump_violations_json(project))
      # copy original pmd reports
      copy_file("#{root}/base_pmd_report.xml", project.report_diff.base_report.file)
      copy_file("#{root}/patch_pmd_report.xml", project.report_diff.patch_report.file)
      # render full pmd reports
      write_file("#{root}/base_pmd_report.html",
                 render_liquid('project_pmd_report.html', pmd_report_liquid_env(project, BASE)))
      write_file("#{root}/base_data.js", dump_violations_json(project, BASE))
      write_file("#{root}/patch_pmd_report.html",
                 render_liquid('project_pmd_report.html', pmd_report_liquid_env(project, PATCH)))
      write_file("#{root}/patch_data.js", dump_violations_json(project, PATCH))
    end

    def dump_violations_json(project, branch = 'diff')
      violations_by_file = if branch == BASE
                             project.report_diff.base_report.violations_by_file.to_h
                           elsif branch == PATCH
                             project.report_diff.patch_report.violations_by_file.to_h
                           else
                             project.report_diff.violation_diffs_by_file
                           end

      h = {
        'source_link_base' => project.webview_url,
        'source_link_template' => link_template(project),
        **violations_to_hash(project, violations_by_file, branch == 'diff')
      }

      project_data = JSON.fast_generate(h, indent: '    ', object_nl: "\n", array_nl: "\n")
      "let project = #{project_data}"
    end

    private

    def copy_file(target_file, source_file)
      if File.exist? source_file
        FileUtils.cp(source_file, target_file)
        logger&.info "Written #{target_file}"
      else
        logger&.warn "File #{source_file} not found"
      end
    end

    def pmd_report_liquid_env(project, branch)
      report = if branch == BASE
                 project.report_diff.base_report
               else
                 project.report_diff.patch_report
               end
      {
        'project_name' => project.name,
        'branch' => branch,
        'report' => report_to_h(project, report)
      }
    end

    def report_to_h(project, report)
      {
        'violation_counts' => report.violations_by_file.total_size,
        'error_counts' => report.errors_by_file.total_size,
        'configerror_counts' => report.configerrors_by_rule.values.flatten.length,

        'execution_time' => PmdReportDetail.convert_seconds(report.exec_time),
        'timestamp' => report.timestamp,

        'rules' => report.rule_summaries,
        'errors' => report.errors_by_file.all_values.map { |e| error_to_hash(e, project) },
        'configerrors' => report.configerrors_by_rule.values.flatten.map { |e| configerror_to_hash(e) }
      }
    end
  end
end
