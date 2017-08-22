path = require 'path'

yargs = require 'yargs'
temp = require 'temp'

Command = require './command'
fs = require './fs'

module.exports =
class Test extends Command
  @commandNames: ['test']

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)

    options.usage """
      Usage:
        recrue test

      Runs the package's tests contained within the spec directory (relative
      to the current working directory).
    """
    options.alias('h', 'help').describe('help', 'Print this usage message')
    options.alias('p', 'path').string('path').describe('path', 'Path to soldat command')

  run: (options) ->
    {callback} = options
    options = @parseOptions(options.commandArgs)
    {env} = process

    soldatCommand = options.argv.path if options.argv.path
    unless fs.existsSync(soldatCommand)
      soldatCommand = 'soldat'
      soldatCommand += '.cmd' if process.platform is 'win32'

    packagePath = process.cwd()
    testArgs = ['--dev', '--test', path.join(packagePath, 'spec')]

    if process.platform is 'win32'
      logFile = temp.openSync(suffix: '.log', prefix: "#{path.basename(packagePath)}-")
      fs.closeSync(logFile.fd)
      logFilePath = logFile.path
      testArgs.push("--log-file=#{logFilePath}")

      @spawn soldatCommand, testArgs, (code) ->
        try
          loggedOutput = fs.readFileSync(logFilePath, 'utf8')
          process.stdout.write("#{loggedOutput}\n") if loggedOutput

        if code is 0
          process.stdout.write 'Tests passed\n'.green
          callback()
        else if code?.message
          callback("Error spawning Soldat: #{code.message}")
        else
          callback('Tests failed')
    else
      @spawn soldatCommand, testArgs, {env, streaming: true}, (code) ->
        if code is 0
          process.stdout.write 'Tests passed\n'.green
          callback()
        else if code?.message
          callback("Error spawning #{soldatCommand}: #{code.message}")
        else
          callback('Tests failed')
