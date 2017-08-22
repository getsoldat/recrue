path = require 'path'

async = require 'async'
_ = require 'underscore-plus'
yargs = require 'yargs'

config = require './recrue'
Command = require './command'
fs = require './fs'

module.exports =
class Dedupe extends Command
  @commandNames: ['dedupe']

  constructor: ->
    @soldatDirectory = config.getSoldatDirectory()
    @soldatPackagesDirectory = path.join(@soldatDirectory, 'packages')
    @soldatNodeDirectory = path.join(@soldatDirectory, '.node-gyp')
    @soldatNpmPath = require.resolve('npm/bin/npm-cli')
    @soldatNodeGypPath = require.resolve('node-gyp/bin/node-gyp')

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)
    options.usage """

      Usage: recrue dedupe [<package_name>...]

      Reduce duplication in the node_modules folder in the current directory.

      This command is experimental.
    """
    options.alias('h', 'help').describe('help', 'Print this usage message')

  installNode: (callback) ->
    installNodeArgs = ['install']
    installNodeArgs.push("--runtime=electron")
    installNodeArgs.push("--target=#{@electronVersion}")
    installNodeArgs.push("--dist-url=#{config.getElectronUrl()}")
    installNodeArgs.push("--arch=#{config.getElectronArch()}")
    installNodeArgs.push('--ensure')

    env = _.extend({}, process.env, {HOME: @soldatNodeDirectory, RUSTUP_HOME: config.getRustupHomeDirPath()})
    env.USERPROFILE = env.HOME if config.isWin32()

    fs.makeTreeSync(@soldatDirectory)
    config.loadNpm (error, npm) =>
      # node-gyp doesn't currently have an option for this so just set the
      # environment variable to bypass strict SSL
      # https://github.com/TooTallNate/node-gyp/issues/448
      useStrictSsl = npm.config.get('strict-ssl') ? true
      env.NODE_TLS_REJECT_UNAUTHORIZED = 0 unless useStrictSsl

      # Pass through configured proxy to node-gyp
      proxy = npm.config.get('https-proxy') or npm.config.get('proxy') or env.HTTPS_PROXY or env.HTTP_PROXY
      installNodeArgs.push("--proxy=#{proxy}") if proxy

      @fork @soldatNodeGypPath, installNodeArgs, {env, cwd: @soldatDirectory}, (code, stderr='', stdout='') ->
        if code is 0
          callback()
        else
          callback("#{stdout}\n#{stderr}")

  getVisualStudioFlags: ->
    if vsVersion = config.getInstalledVisualStudioFlag()
      "--msvs_version=#{vsVersion}"

  dedupeModules: (options, callback) ->
    process.stdout.write 'Deduping modules '

    @forkDedupeCommand options, (args...) =>
      @logCommandResults(callback, args...)

  forkDedupeCommand: (options, callback) ->
    dedupeArgs = ['--globalconfig', config.getGlobalConfigPath(), '--userconfig', config.getUserConfigPath(), 'dedupe']
    dedupeArgs.push("--runtime=electron")
    dedupeArgs.push("--target=#{@electronVersion}")
    dedupeArgs.push("--arch=#{config.getElectronArch()}")
    dedupeArgs.push('--silent') if options.argv.silent
    dedupeArgs.push('--quiet') if options.argv.quiet

    if vsArgs = @getVisualStudioFlags()
      dedupeArgs.push(vsArgs)

    dedupeArgs.push(packageName) for packageName in options.argv._

    env = _.extend({}, process.env, {HOME: @soldatNodeDirectory, RUSTUP_HOME: config.getRustupHomeDirPath()})
    env.USERPROFILE = env.HOME if config.isWin32()
    dedupeOptions = {env}
    dedupeOptions.cwd = options.cwd if options.cwd

    @fork(@soldatNpmPath, dedupeArgs, dedupeOptions, callback)

  createSoldatDirectories: ->
    fs.makeTreeSync(@soldatDirectory)
    fs.makeTreeSync(@soldatNodeDirectory)

  run: (options) ->
    {callback, cwd} = options
    options = @parseOptions(options.commandArgs)
    options.cwd = cwd

    @createSoldatDirectories()

    commands = []
    commands.push (callback) => @loadInstalledSoldatMetadata(callback)
    commands.push (callback) => @installNode(callback)
    commands.push (callback) => @dedupeModules(options, callback)
    async.waterfall commands, callback
