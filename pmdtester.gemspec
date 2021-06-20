# DO NOT EDIT THIS FILE. Instead, edit Rakefile, and run `rake hoe:spec`.

# -*- encoding: utf-8 -*-
# stub: pmdtester 1.2.0.pre.SNAPSHOT ruby lib

Gem::Specification.new do |s|
  s.name = "pmdtester".freeze
  s.version = "1.2.0.pre.SNAPSHOT"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/pmd/pmd-regression-tester/issues", "homepage_uri" => "https://pmd.github.io", "source_code_uri" => "https://github.com/pmd/pmd-regression-tester" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andreas Dangel".freeze, "Binguo Bao".freeze, "Cl\u00E9ment Fournier".freeze]
  s.date = "2021-06-20"
  s.description = "A regression testing tool ensure that new problems and unexpected behaviors will not be introduced to PMD project after fixing an issue , and new rules can work as expected.".freeze
  s.email = ["andreas.dangel@pmd-code.org".freeze, "djydewang@gmail.com".freeze, "clement.fournier76@gmail.com".freeze]
  s.executables = ["pmdtester".freeze]
  s.extra_rdoc_files = ["History.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = [".ci/build.sh".freeze, ".ci/inc/fetch_ci_scripts.bash".freeze, ".ci/manual-integration-tests.sh".freeze, ".github/workflows/build.yml".freeze, ".github/workflows/manual-integration-tests.yml".freeze, ".gitignore".freeze, ".hoerc".freeze, ".rubocop.yml".freeze, ".rubocop_todo.yml".freeze, ".ruby-version".freeze, "Gemfile".freeze, "History.md".freeze, "LICENSE".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "bin/pmdtester".freeze, "config/all-java.xml".freeze, "config/design.xml".freeze, "config/project-list.xml".freeze, "config/projectlist_1_0_0.xsd".freeze, "config/projectlist_1_1_0.xsd".freeze, "config/projectlist_1_2_0.xsd".freeze, "lib/pmdtester.rb".freeze, "lib/pmdtester/builders/liquid_renderer.rb".freeze, "lib/pmdtester/builders/pmd_report_builder.rb".freeze, "lib/pmdtester/builders/project_builder.rb".freeze, "lib/pmdtester/builders/project_hasher.rb".freeze, "lib/pmdtester/builders/rule_set_builder.rb".freeze, "lib/pmdtester/builders/simple_progress_logger.rb".freeze, "lib/pmdtester/builders/summary_report_builder.rb".freeze, "lib/pmdtester/cmd.rb".freeze, "lib/pmdtester/collection_by_file.rb".freeze, "lib/pmdtester/parsers/options.rb".freeze, "lib/pmdtester/parsers/pmd_report_document.rb".freeze, "lib/pmdtester/parsers/projects_parser.rb".freeze, "lib/pmdtester/pmd_branch_detail.rb".freeze, "lib/pmdtester/pmd_configerror.rb".freeze, "lib/pmdtester/pmd_error.rb".freeze, "lib/pmdtester/pmd_report_detail.rb".freeze, "lib/pmdtester/pmd_tester_utils.rb".freeze, "lib/pmdtester/pmd_violation.rb".freeze, "lib/pmdtester/project.rb".freeze, "lib/pmdtester/report_diff.rb".freeze, "lib/pmdtester/resource_locator.rb".freeze, "lib/pmdtester/runner.rb".freeze, "pmdtester.gemspec".freeze, "resources/_includes/diff_pill_row.html".freeze, "resources/css/bootstrap.min.css".freeze, "resources/css/datatables.min.css".freeze, "resources/css/pmd-tester.css".freeze, "resources/js/bootstrap.min.js".freeze, "resources/js/code-snippets.js".freeze, "resources/js/datatables.min.js".freeze, "resources/js/jquery-3.2.1.slim.min.js".freeze, "resources/js/jquery.min.js".freeze, "resources/js/popper.min.js".freeze, "resources/js/project-report.js".freeze, "resources/project_diff_report.html".freeze, "resources/project_index.html".freeze, "resources/project_pmd_report.html".freeze]
  s.homepage = "https://pmd.github.io".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "A regression testing tool ensure that new problems and unexpected behaviors will not be introduced to PMD project after fixing an issue , and new rules can work as expected.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.11.0.rc4"])
    s.add_runtime_dependency(%q<slop>.freeze, ["~> 4.6"])
    s.add_runtime_dependency(%q<differ>.freeze, ["~> 0.1"])
    s.add_runtime_dependency(%q<rufus-scheduler>.freeze, ["~> 3.5"])
    s.add_runtime_dependency(%q<logger-colors>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<liquid>.freeze, [">= 4.0"])
    s.add_development_dependency(%q<hoe-bundler>.freeze, ["~> 1.5"])
    s.add_development_dependency(%q<hoe-git>.freeze, ["~> 1.6"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.10"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 1.5"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.81"])
    s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.2"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_development_dependency(%q<hoe>.freeze, ["~> 3.22"])
  else
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.11.0.rc4"])
    s.add_dependency(%q<slop>.freeze, ["~> 4.6"])
    s.add_dependency(%q<differ>.freeze, ["~> 0.1"])
    s.add_dependency(%q<rufus-scheduler>.freeze, ["~> 3.5"])
    s.add_dependency(%q<logger-colors>.freeze, ["~> 1.0"])
    s.add_dependency(%q<liquid>.freeze, [">= 4.0"])
    s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.5"])
    s.add_dependency(%q<hoe-git>.freeze, ["~> 1.6"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.10"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.5"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.81"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.2"])
    s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.22"])
  end
end

# DO NOT EDIT THIS FILE. Instead, edit Rakefile, and run `rake hoe:spec`.
