`#!/usr/bin/env node
`

# github-todotxt.coffee
# Get data from Github issues and format it for todo.txt
#
# Copyright 2016 Evan Prodromou <evan@prodromou.name>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

fs = require 'fs'
path = require 'path'

_ = require 'lodash'
yargs = require 'yargs'
GitHubApi = require 'github'
async = require 'async'
split = require 'split'

argv = yargs
  .usage('Usage: $0 -t [token]')
  .demand('t')
  .alias('t', 'token')
  .describe('t', 'OAuth token')
  .alias('f', 'file')
  .describe('f', 'todo.txt file')
  .default('f', path.join(process.env.HOME, "Dropbox", "todo", "todo.txt"))
  .env('GITHUB_TODOTXT')
  .alias('c', 'config')
  .describe('c', 'Config file')
  .default('c', path.join(process.env.HOME, ".github-todotxt.json"))
  .config('config')
  .help('h')
  .alias('h', 'help')
  .argv

projectCase = (str) ->
  _.upperFirst _.camelCase str

token = argv.t
filename = argv.f

github = new GitHubApi
  debug: false

github.authenticate
  type: "oauth"
  token: token

async.parallel [
  (callback) ->
    todos = []
    fs.createReadStream(filename)
      .pipe(split())
      .on 'data', (line) ->
        if line.match /\S/
          m = line.match /issue:(\S+)/
          todo =
            text: line
          if m
            todo.issue = m[1]
          todos.push todo
      .on 'error', (err) ->
        callback err, null
      .on 'end', ->
        callback null, todos
  (callback) ->
    getIssues = (page, acc, callback) ->
      props =
        state: "all"
        filter: "assigned"
        per_page: 100
        page: page
      github.issues.getAll props, (err, issues) ->
        if err
          callback err
        else
          acc = _.concat acc, issues
          if issues.length >= 100
            getIssues page + 1, acc, callback
          else
            callback null, acc
    getIssues 1, [], callback
], (err, results) ->
  if err
    console.error err
  else
    [todos, issues] = results
    console.dir {todos: todos.length, issues: issues.length}
    for issue in issues
      repo = issue.repository.full_name
      number = issue.number
      id = "#{repo}##{number}"
      todo = _.find todos, {issue: id}
      if todo?
        if todo.text.match /^x/
          if issue.state is "open"
            "not closing issue"
            # XXX: close the github issue
        else
          if issue.state is "closed"
            todo.text = "x #{todo.text}"
      else if issue.state is "open"
        ts = issue.created_at.substr(0, 10)
        project = projectCase repo.split("/")[1]
        title = issue.title
        line = "#{ts} #{title} issue:#{repo}##{number} +#{project}"
        if issue.milestone?
          line += " +#{projectCase(issue.milestone.title)}"
        todos.push {text: line}
    backup = "#{filename}.bak"
    async.waterfall [
      (callback) ->
        fs.rename filename, backup, callback
      (callback) ->
        texts = _.map todos, "text"
        data = texts.join("\n") + "\n"
        fs.writeFile filename, data, callback
    ], (err) ->
      if err
        console.error err
