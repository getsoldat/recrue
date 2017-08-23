child_process = require 'child_process'
fs = require './fs'
path = require 'path'
npm = require 'npm'
semver = require 'semver'

module.exports =
  getHomeDirectory: ->
    if process.platform is 'win32' then process.env.USERPROFILE else process.env.HOME

  getSoldatDirectory: ->
    process.env.SOLDAT_HOME ? path.join(@getHomeDirectory(), '.soldat')

  getRustupHomeDirPath: ->
    if process.env.RUSTUP_HOME
      process.env.RUSTUP_HOME
    else
      path.join(@getHomeDirectory(), '.multirust')

  getCacheDirectory: ->
    path.join(@getSoldatDirectory(), '.recrue')

  getResourcePath: (callback) ->

    if process.env.SOLDAT_RESOURCE_PATH
      return process.nextTick -> callback(process.env.SOLDAT_RESOURCE_PATH)

    recrueFolder = path.resolve(__dirname, '..')
    appFolder = path.dirname(recrueFolder)

    if path.basename(recrueFolder) is 'recrue' and path.basename(appFolder) is 'app'
      asarPath = "#{appFolder}.asar"
      if fs.existsSync(asarPath)
        return process.nextTick -> callback(asarPath)

    recrueFolder = path.resolve(__dirname, '..', '..', '..')
    appFolder = path.dirname(recrueFolder)
    if path.basename(recrueFolder) is 'recrue' and path.basename(appFolder) is 'app'
      asarPath = "#{appFolder}.asar"
      if fs.existsSync(asarPath)
        return process.nextTick -> callback(asarPath)

    switch process.platform
      when 'darwin'
        child_process.exec 'mdfind "kMDItemCFBundleIdentifier == \'tv.soldat.soldat\'"', (error, stdout='', stderr) ->
          [appLocation] = stdout.split('\n') unless error
          appLocation = '/Applications/Soldat.app' unless appLocation
          callback("#{appLocation}/Contents/Resources/app.asar")
      when 'linux'
        appLocation = '/usr/local/share/soldat/resources/app.asar'
        unless fs.existsSync(appLocation)
          appLocation = '/usr/share/soldat/resources/app.asar'
        process.nextTick -> callback(appLocation)

  getReposDirectory: ->
    process.env.SOLDAT_REPOS_HOME ? path.join(@getHomeDirectory(), 'github')

  getElectronUrl: ->
    process.env.SOLDAT_ELECTRON_URL ? 'https://atom.io/download/electron'

  getSoldatPackagesUrl: ->
    process.env.SOLDAT_PACKAGES_URL ? "#{@getSoldatApiUrl()}/packages"

  getSoldatApiUrl: ->
    process.env.SOLDAT_API_URL ? 'https://soldat.lemarier.sh/'

  getElectronArch: ->
    switch process.platform
      when 'darwin' then 'x64'
      else process.env.SOLDAT_ARCH ? process.arch

  getUserConfigPath: ->
    path.resolve(@getSoldatDirectory(), '.recruerc')

  getGlobalConfigPath: ->
    path.resolve(@getSoldatDirectory(), '.recrue', '.recruerc')

  isWin32: ->
    process.platform is 'win32'

  x86ProgramFilesDirectory: ->
    process.env["ProgramFiles(x86)"] or process.env["ProgramFiles"]

  getInstalledVisualStudioFlag: ->
    return null unless @isWin32()

    # Use the explictly-configured version when set
    return process.env.GYP_MSVS_VERSION if process.env.GYP_MSVS_VERSION

    return '2015' if @visualStudioIsInstalled("14.0")
    return '2013' if @visualStudioIsInstalled("12.0")
    return '2012' if @visualStudioIsInstalled("11.0")
    return '2010' if @visualStudioIsInstalled("10.0")

  visualStudioIsInstalled: (version) ->
    fs.existsSync(path.join(@x86ProgramFilesDirectory(), "Microsoft Visual Studio #{version}", "Common7", "IDE"))

  loadNpm: (callback) ->
    npmOptions =
      userconfig: @getUserConfigPath()
      globalconfig: @getGlobalConfigPath()
    npm.load npmOptions, -> callback(null, npm)

  getSetting: (key, callback) ->
    @loadNpm -> callback(npm.config.get(key))

  setupApmRcFile: ->
    try
      fs.writeFileSync @getGlobalConfigPath(), """
        ; This file is auto-generated and should not be edited since any
        ; modifications will be lost the next time any recrue command is run.
        ;
        ; You should instead edit your .recruerc config located in ~/.soldat/.recruerc
        cache = #{@getCacheDirectory()}
        ; Hide progress-bar to prevent npm from altering recrue console output.
        progress = false
      """
