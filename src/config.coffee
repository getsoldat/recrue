path = require 'path'
_ = require 'underscore-plus'
yargs = require 'yargs'
recrue = require './recrue'
Command = require './command'

module.exports =
class Config extends Command
  @commandNames: ['config']

  constructor: ->
    soldatDirectory = recrue.getSoldatDirectory()
    @soldatNodeDirectory = path.join(soldatDirectory, '.node-gyp')
    @soldatNpmPath = require.resolve('npm/bin/npm-cli')

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)
    options.usage """

      Usage: recrue config set <key> <value>
             recrue config get <key>
             recrue config delete <key>
             recrue config list
             recrue config edit

    """
    options.alias('h', 'help').describe('help', 'Print this usage message')

  run: (options) ->
    {callback} = options
    options = @parseOptions(options.commandArgs)

    configArgs = ['--globalconfig', recrue.getGlobalConfigPath(), '--userconfig', recrue.getUserConfigPath(), 'config']
    configArgs = configArgs.concat(options.argv._)

    env = _.extend({}, process.env, {HOME: @soldatNodeDirectory, RUSTUP_HOME: recrue.getRustupHomeDirPath()})
    configOptions = {env}

    @fork @soldatNpmPath, configArgs, configOptions, (code, stderr='', stdout='') ->
      if code is 0
        process.stdout.write(stdout) if stdout
        callback()
      else
        process.stdout.write(stderr) if stderr
        callback(new Error("npm config failed: #{code}"))
