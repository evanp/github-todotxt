#!/usr/bin/env node
// github-todotxt.js
// Get data from Github issues and format it for todo.txt
//
// Copyright 2016-2019 Evan Prodromou <evan@prodromou.name>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const fs = require('fs')
const path = require('path')

const _ = require('lodash')
const yargs = require('yargs')
const Octokit = require('@octokit/rest')
const split = require('split')

const { argv } = yargs
  .usage('Usage: $0 -t [token]')
  .demand('t')
  .alias('t', 'token')
  .describe('t', 'OAuth token')
  .alias('f', 'file')
  .describe('f', 'todo.txt file')
  .default('f', path.join(process.env.HOME, 'Dropbox', 'todo', 'todo.txt'))
  .alias('q', 'quiet')
  .describe('q', 'Minimize console output')
  .env('GITHUB_TODOTXT')
  .alias('c', 'config')
  .describe('c', 'Config file')
  .default('c', path.join(process.env.HOME, '.github-todotxt.json'))
  .config('config')
  .help('h')
  .alias('h', 'help')

const projectCase = str => _.upperFirst(_.camelCase(str))
const markComplete = function (text, completed) {
  const m = text.match(/^\s*\(([A-Z])\)\s*/)
  if (m) {
    return `x ${completed} ${text.substr(m[0].length)} pri:${m[1]}`
  } else {
    return `x ${completed} ${text}`
  }
}

const getTodos = async function (filename) {
  return new Promise((resolve, reject) => {
    const todos = []
    fs.createReadStream(filename)
      .pipe(split())
      .on('data', (line) => {
        if (line.match(/\S/)) {
          const m = line.match(/issue:(\S+)/)
          const todo =
            {text: line}
          if (m) {
            [, todo.issue] = m
          }
          todos.push(todo)
        }
      })
      .on('error', reject)
      .on('end', () => {
        resolve(todos)
      })
  })
}

const writeTodos = async function (filename, todos) {
  return new Promise((resolve, reject) => {
    const ws = fs.createWriteStream(filename)
      .on('error', reject)
      .on('finish', resolve)

    for (const todo of todos) {
      ws.write(`${todo.text}\n`, 'utf-8')
    }

    ws.end()
  })
}

const rename = async function (oldname, newname) {
  return new Promise((resolve, reject) => {
    fs.rename(oldname, newname, (err) => {
      if (err) {
        reject(err)
      } else {
        resolve()
      }
    })
  })
}

const main = async function (argv) {
  const token = argv.t
  const filename = argv.f
  const quiet = (argv.q != null)

  const note = function (str) {
    if (!quiet) {
      return process.stdout.write(str)
    }
  }

  const github = new Octokit({
    auth: token
  })

  const issues = await github.paginate('GET /issues')
  const todos = await getTodos(filename)

  if (!quiet) {
    note(`${todos.length} lines in ${filename}\n`)
    note(`${issues.length} issues on Github\n`)
  }

  let repo, id, todo, number

  for (const issue of Array.from(issues)) {
    repo = issue.repository.full_name;
    ({ number } = issue)
    id = `${repo}#${number}`
    todo = _.find(todos, {issue: id})
    if (todo != null) {
      if (todo.text.match(/^x/)) {
        if (issue.state === 'open') {
          note('not closing issue')
        }
        // XXX: close the github issue
      } else {
        if (issue.state === 'closed') {
          note(`Marking line for issue ${id} complete.\n`)
          const completed = (issue.closed_at)
            ? issue.closed_at.substr(0, 10)
            : (new Date()).toISOString().substr(0, 10)
          const {text} = todo
          todo.text = markComplete(text, completed)
        }
      }
    } else if (issue.state === 'open') {
      note(`Adding line for issue ${id}.\n`)
      const ts = issue.created_at.substr(0, 10)
      const project = projectCase(repo.split('/')[1])
      const { title } = issue
      let line = `${ts} ${title} issue:${repo}#${number} +${project}`
      if (issue.milestone != null) {
        line += ` +${projectCase(issue.milestone.title)}`
      }
      todos.push({text: line})
    }
  }

  // Todos with issues that aren't in the list should be marked as done.

  for (todo of Array.from(todos)) {
    if ((todo.issue == null)) {
      continue
    }
    if (todo.text.match(/^x/)) {
      continue
    }
    const issue = _.find(issues, (issue) => {
      repo = issue.repository.full_name;
      ({ number } = issue)
      id = `${repo}#${number}`
      return id === todo.issue
    })
    if ((issue == null)) {
      note(`Issue ${todo.issue} not assigned to you; marking it done.\n`)
      const completed = (new Date()).toISOString().substr(0, 10)
      todo.text = markComplete(todo.text, completed)
    }
  }

  const backup = `${filename}.bak`

  note(`Backing up ${filename} to ${backup}...\n`)

  await rename(filename, backup)

  await writeTodos(filename, todos)
}

main(argv)
