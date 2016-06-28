fs = require 'fs'

{spawn} = require 'child_process'

glob = require 'glob'

cmd = (str, callback) ->

  parts = str.split(' ')
  main = parts[0]
  rest = parts.slice(1)
  proc = spawn main, rest
  out = ''
  err = ''

  proc.stderr.on 'data', (data) ->
    err += data.toString()

  proc.stdout.on 'data', (data) ->
    out += data.toString()

  proc.on 'exit', (code) ->
    if code is 0
      callback?(out, err)
    else
      process.exit(code)

task 'build', 'Build lib/ from src/', ->
  cmd 'coffee -cp github-todotxt.coffee', (output) ->
    shebang = "#!/usr/bin/env node"
    fs.writeFileSync './github-todotxt.js', shebang + "\n" + output + "\n"
