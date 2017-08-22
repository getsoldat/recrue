path = require 'path'

_ = require 'underscore-plus'
yargs = require 'yargs'

config = require './recrue'
Command = require './command'
Install = require './install'

module.exports =
class Rebuild extends Command
  @commandNames: ['rebuild']

  constructor: ->
    @soldatNodeDirectory = path.join(config.getSoldatDirectory(), '.node-gyp')
    @soldatNpmPath = require.resolve('npm/bin/npm-cli')

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)
    options.usage """

      Usage: recrue rebuild [<name> [<name> ...]]

      Rebuild the given modules currently installed in the node_modules folder
      in the current working directory.

      All the modules will be rebuilt if no module names are specified.
    """
    options.alias('h', 'help').describe('help', 'Print this usage message')

  installNode: (callback) ->
    config.loadNpm (error, npm) ->
      install = new Install()
      install.npm = npm
      install.loadInstalledSoldatMetadata -> install.installNode(callback)

  forkNpmRebuild: (options, callback) ->
    process.stdout.write 'Rebuilding modules '

    rebuildArgs = [
      '--globalconfig'
      config.getGlobalConfigPath()
      '--userconfig'
      config.getUserConfigPath()
      'rebuild'
      '--runtime=electron'
      "--target=#{@electronVersion}"
      "--arch=#{config.getElectronArch()}"
    ]
    rebuildArgs = rebuildArgs.concat(options.argv._)

    if vsArgs = @getVisualStudioFlags()
      rebuildArgs.push(vsArgs)

    env = _.extend({}, process.env, {HOME: @soldatNodeDirectory, RUSTUP_HOME: config.getRustupHomeDirPath()})
    env.USERPROFILE = env.HOME if config.isWin32()
    @addBuildEnvVars(env)

    @fork(@soldatNpmPath, rebuildArgs, {env}, callback)

  run: (options) ->
    {callback} = options
    options = @parseOptions(options.commandArgs)

    config.loadNpm (error, @npm) =>
      @loadInstalledSoldatMetadata =>
        @installNode (error) =>
          return callback(error) if error?

          @forkNpmRebuild options, (code, stderr='') =>
            if code is 0
              @logSuccess()
              callback()
            else
              @logFailure()
              callback(stderr)
