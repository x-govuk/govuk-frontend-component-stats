require 'json'
require 'csv'

govuk_frontend_versions = {}

components = [
  {macro: "govukAccordion", class: "govuk-accordion", name: "Accordion"},
  {macro: "govukBackLink", class: "govuk-back-link", name: "Back Link"},
  {macro: "govukBreadcrumbs", class: "govuk-breadcrumbs", name: "Breadcrumbs"},
  {macro: "govukButton", class: "govuk-button", name: "Button"},
  {macro: "govukCharacterCount", class: "govuk-character-count", name: "Character count"},
  {macro: "govukCheckboxes", class: "govuk-checkboxes", name: "Checkboxes"},
  {macro: "govukCookieBanner", class: "govuk-cookie-banner", name: "Cookie Banner"},
  {macro: "govukDateInput", class: "govuk-date-input", name: "Date input"},
  {macro: "govukDetails", class: "govuk-details", name: "Details"},
  {macro: "govukErrorMessage", class: "govuk-error-message", name: "Error message"},
  {macro: "govukErrorSummary", class: "govuk-error-summary", name: "Error summary"},
  {macro: "govukFieldset", class: "govuk-fieldset", name: "Fieldset"},
  {macro: "govukFileUpload", class: "govuk-file-upload", name: "File upload"},
  {macro: "govukFooter", class: "govuk-footer", name: "Footer"},
  {macro: "govukHeader", class: "govuk-header", name: "Header"},
  {macro: "govukInsetText", class: "govuk-inset-text", name: "Inset text"},
  {macro: "govukNotificationBanner", class: "govuk-notification-banner", name: "Notification banner"},
  {macro: "govukPanel", class: "govuk-panel", name: "Panel"},
  {macro: "govukPhaseBanner", class: "govuk-phase-banner", name: "Phase banner"},
  {macro: "govukRadios", class: "govuk-radios", name: "Radios"},
  {macro: "govukSelect", class: "govuk-select", name: "Select"},
  {macro: "govukSkipLink", class: "govuk-skip-link", name: "Skip link"},
  {macro: "govukSummaryList", class: "govuk-summary-list", name: "Summary list"},
  {macro: "govukTable", class: "govuk-table", name: "Table"},
  {macro: "govukTabs", class: "govuk-tabs", name: "Tabs"},
  {macro: "govukTag", class: "govuk-tag", name: "Tag"},
  {macro: "govukInput", class: "govuk-input", name: "Text input"},
  {macro: "govukTextarea", class: "govuk-textarea", name: "Textarea"},
  {macro: "govukWarningText", class: "govuk-warning-text", name: "Warning text"},
  {macro: "appTaskList", class: "-task-list", name: "Task list"}
]

templating_languages = [
  {name: "Nunjucks", extension: "njk"},
  {name: "HTML", extension: "html"},
  {name: "TypeScript", extension: "tsx"},
  {name: "React", extension: "jsx"},
  {name: "ERb", extension: "erb"},
  {name: "Slim", extension: "slim"},
  {name: "FreeMarker", extension: "ftl"},
  {name: "HAML", extension: "haml"},
  {name: "EJS", extension: "ejs"},
  {name: "Markdown", extension: "md"}
]

repos = 0
nunjucks_repos = 0
govuk_frontend_repos = 0
govuk_frontend_toolkit_repos = 0
govuk_frontend_and_toolkit_repos = 0
prototypes = 0
ruby_repos = 0
python_repos = 0

component_overall_usage = {}

csv_headers = ["Department", "repo"]
csv_headers.concat components.collect {|c| c[:name] }

csv_headers.concat templating_languages.collect {|tl| tl[:name] }

csv = [csv_headers]

Dir.glob("repos/*/*") do |folder|

  repos += 1

  if File.exist?(folder + "/package.json")
    begin
      package = JSON.parse(File.read(folder + "/package.json"))
    rescue JSON::ParserError
      next
    end


    govuk_frontend_toolkit_repos += 1 if package.dig('dependencies', 'govuk_frontend_toolkit')

    govuk_frontend_version = package.dig("dependencies", "govuk-frontend")

    govuk_frontend_and_toolkit_repos += 1 if package.dig('dependencies', 'govuk_frontend_toolkit') && govuk_frontend_version

    prototypes += 1 if package.dig('dependencies', 'browser-sync')

    if govuk_frontend_version
      govuk_frontend_repos += 1
      govuk_frontend_versions[govuk_frontend_version] ||= 0
      govuk_frontend_versions[govuk_frontend_version] += 1

      ruby_repos += 1 if File.exist?(folder + "/Gemfile.lock")
      python_repos += 1 if File.exist?(folder + "/requirements.txt")
      nunjucks_repos += 1 if package.dig('dependencies', 'nunjucks')

#       if !File.exist?(folder + "/Gemfile.lock") &&
#         !File.exist?(folder + "/requirements.txt") &&
#         !package["dependencies"]["nunjucks"]
#
#         puts folder
#       end

    end

    if govuk_frontend_version


      repo_component_usage = {}
      repo_templating_language_usage = {}

      Dir.glob(folder + "/**/*.{#{templating_languages.collect {|t| t[:extension] }.join(',')}}") do |nunjucks_file|
        if !nunjucks_file.include?("node_modules/") &&
          !nunjucks_file.include?("src/govuk-frontend/") &&
          !nunjucks_file.include?("docs/") &&
          !nunjucks_file.include?("/prototype-admin/")

          next unless File.file?(nunjucks_file)  # skip folders
          file = File.read(nunjucks_file)

          components.each do |component|
            if file.include?(component[:macro] + "(") || file.include?(component[:class])
              repo_component_usage[component[:macro]] ||= 0
              repo_component_usage[component[:macro]] += 1

              file_extension = nunjucks_file.split(".").last

              repo_templating_language_usage[file_extension] ||= 1

            end
          end
        end
      end

      repo_component_usage.each_pair do |component, count|
        component_overall_usage[component] ||= 0
        component_overall_usage[component] += 1
      end

      if repo_component_usage == {}
        puts folder
      end

      department = []

      csv_line = [
        folder.split("/")[1],
        folder.split("/").last
      ]

      components.each do |component|
        csv_line << (repo_component_usage[component[:macro]] ? "1" : "0")
      end

      templating_languages.each do |tl|
        csv_line << (repo_templating_language_usage[tl[:extension]] ? "1" : "0")
      end

      csv << csv_line
    end

  end

end

puts "#{repos} repos found"
puts "#{govuk_frontend_repos} govuk-frontend repos found, of which"
puts "...#{prototypes} prototypes found"
puts "...#{nunjucks_repos} nunjucks repos found"
puts "...#{ruby_repos} ruby repos found"
puts "...#{python_repos} python repos found"
puts "#{govuk_frontend_toolkit_repos} govuk-frontend-toolkit repos found"
puts "#{govuk_frontend_and_toolkit_repos} repos with govuk-frontend AND govuk-frontend-toolkit"

CSV.open("stats.csv", "wb") do |file|
  # file << ["A", "B"]
  csv.each {|line| file << line }
end

component_overall_usage.collect {|component, count| [component,count] }
  .sort_by {|x| x[1] }
  .reverse
  .each {|component, count| puts "#{count} - #{component}"}
