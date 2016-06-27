# github-todotxt.coffee
# Get data from Github issues and format it for todo.txt

_ = require 'lodash'
yargs = require 'yargs'
GitHubApi = require 'github'
async = require 'async'

argv = yargs
  .usage('Usage: $0 -t [token]')
  .demand('t')
  .alias('t', 'token')
  .describe('t', 'OAuth token')
  .help('h')
  .alias('h', 'help')
  .argv

projectCase = (str) ->
  _.upperFirst _.camelCase str

token = argv.t

github = new GitHubApi
  debug: false

github.authenticate
  type: "oauth"
  token: token

github.issues.getAll {state: "open"}, (err, issues) ->
  for issue in issues
    repo = issue.repository.full_name
    ts = issue.created_at.substr(0, 10)
    project = projectCase repo.split("/")[1]
    title = issue.title
    number = issue.number
    line = "#{ts} #{title} issue:#{repo}##{number} +#{project}"
    if issue.milestone?
      line += " +#{projectCase(issue.milestone.title)}"
    console.log line
