recrue = require './recrue-cli'

process.title = 'recrue'

recrue.run process.argv.slice(2), (error) ->
  process.exitCode = if error? then 1 else 0
