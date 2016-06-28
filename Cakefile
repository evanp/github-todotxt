fs = require 'fs'

{spawn} = require 'child_process'

glob = require 'glob'

cmd = (str, callback) ->
  parts = str.split(' ')
  main = parts[0]
  rest = parts.slice(1)
  proc = spawn main, rest
  proc.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  proc.stdout.on 'data', (data) ->
    process.stdout.write data.toString()
  proc.on 'exit', (code) ->
    if code is 0
      callback?()
    else
      process.exit(code)

task 'build', 'Build lib/ from src/', ->
  cmd 'coffee -c github-todotxt.coffee'
  

