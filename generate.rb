require 'octokit'
require 'uri'
require 'git'

# Token needs no privileges at all.
client = Octokit::Client.new(:access_token => ENV.fetch('GITHUB_ACCESS_TOKEN'))

organisations = ['alphagov', 'cabinetoffice', 'communitiesuk', 'DFE-Digital', 'departmentfortransport', 'hmrc', 'dwp', 'defra', 'dfid', 'MHRA', 'ministryofjustice', 'ukforeignoffice', 'UKHomeOffice', 'UKGovernmentBEIS', 'companieshouse', 'decc', 'dvla', 'dvsa', 'insolvencyservice', 'intellectual-property-office', 'LandRegistry', 'MHRA', 'OfqualGovUK', 'SkillsFundingAgency', 'publichealthengland', 'hmcts', 'department-of-health', 'uktrade', 'mcagov', 'HMPO', 'Planning-Inspectorate', 'digital-land', 'FoodStandardsAgency']


ignored_repos = File.read('ignored_repos.txt').split("\n")

repos = []

organisations.each do |org|
  repos.concat(client.repositories(org))

  page = 1

  while page < 500 do
    puts "#{org} page #{page}"

    next_url = client.last_response.rels[:next]

    break if next_url.nil?

    repos.concat(client.get(next_url.href))
    page += 1
  end
end

repos.each do |repo|
  next if Dir.exists?("repos/#{repo.full_name}")
  next if ignored_repos.include?(repo)
  puts "Cloning #{repo.full_name}"
  begin
    Git.clone(repo.git_url, "repos/#{repo.full_name}", depth: 1)
  rescue Git::GitExecuteError
    puts "Error clonining #{repo.full_name}"
  end
end
