# github-todotxt.coffee
# Get data from Github issues and format it for todo.txt

_ = require 'lodash'
yargs = require 'yargs'
GitHubApi = require 'github'

argv = yargs
  .usage('Usage: $0 -t [token] -r [repo] -a [assignee] -p [project]')
  .demand('t')
  .alias('t', 'token')
  .describe('t', 'OAuth token')
  .demand('r')
  .alias('r', 'repository')
  .describe('r', 'repository to use (username/project)')
  .default('a', null, 'no filter')
  .alias('a', 'assignee')
  .describe('a', 'Filter by assignee')
  .default('p', null, 'last half of repo name')
  .alias('p', 'project')
  .describe('p', 'Use this name for project')
  .help('h')
  .alias('h', 'help')
  .argv

projectCase = (str) ->
  _.upperFirst _.camelCase str

repo = argv.r
token = argv.t

if argv.p?
  project = argv.p
else
  project = projectCase repo.split("/")[1]

github = new GitHubApi
  debug: false

github.authenticate
  type: "oauth"
  token: token

[username, reponame] = repo.split("/")

props =
  user: username
  repo: reponame

if argv.a
  props.assignee = argv.a

github.issues.getForRepo props, (err, res) ->
  if err
    console.error err
  else
    issues = _.sortBy res, "number"
    for issue in issues
      ts = issue.created_at.substr(0, 10)
      line = "#{ts} #{issue.title} issue:#{repo}##{issue.number} +#{project}"
      if issue.milestone?
        line += " +#{projectCase(issue.milestone.title)}"
      console.log line
