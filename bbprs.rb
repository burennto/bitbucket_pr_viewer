require 'yaml'
require 'io/console'
require 'net/http'
require 'json'
require 'colored'
require 'terminal-table'

CONFIG = YAML.load_file('config.yml')

OWNER = CONFIG['owner']
REPOS = CONFIG['repos'].map!(&:chomp)

puts "\n"

print 'Bitbucket username: '
username = gets.chomp

puts "\n"

print 'Bitbucket password: '
password = STDIN.noecho(&:gets).chomp

puts "\n\n"

REPOS.each do |repo_slug|
  print "\r"
  print "#{repo_slug}...\r"

  uri = URI("https://bitbucket.org/api/2.0/repositories/#{OWNER}/#{repo_slug}/pullrequests?state=OPEN&state=MERGED&state=DECLINED&pagelen=50")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth(username, password)

  response        = http.request(request).body
  parsed_response = JSON.parse(response)

  pull_requests = parsed_response['values']

  next if pull_requests.nil? || pull_requests.empty?

  rows = pull_requests.inject([]) do |memo, pr|
    id     = pr['id'].to_s
    author = pr['author']['display_name']
    title  = pr['title']
    state  = pr['state']

    row = [ id, author, title, state ]

    row.map!(&:green) if pr['state'].upcase == 'OPEN'
    row.map!(&:blue)  if pr['state'].upcase == 'MERGED'
    row.map!(&:red)   if pr['state'].upcase == 'DECLINED'

    memo << row
    memo
  end

  table = Terminal::Table.new(
    :title    => repo_slug,
    :headings => %w(ID Author Title State),
    :rows     => rows
  )

  puts table
end
