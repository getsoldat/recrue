fs = require 'fs-plus'
wrench = require 'wrench'
path = require 'path'
temp = require 'temp'
CSON = require 'season'

recrue = require '../lib/recrue-cli'

describe 'recrue disable', ->
  beforeEach ->
    silenceOutput()
    spyOnToken()

  it 'disables an enabled package', ->
    soldatHome = temp.mkdirSync('recrue-home-dir-')
    process.env.SOLDAT_HOME = soldatHome
    callback = jasmine.createSpy('callback')
    configFilePath = path.join(soldatHome, 'config.cson')

    CSON.writeFileSync configFilePath, '*':
      core:
        disabledPackages: [
          "test-module"
        ]

    packagesPath = path.join(soldatHome, 'packages')
    packageSrcPath = path.join(__dirname, 'fixtures')
    fs.makeTreeSync(packagesPath)
    wrench.copyDirSyncRecursive(path.join(packageSrcPath, 'test-module'), path.join(packagesPath, 'test-module'))
    wrench.copyDirSyncRecursive(path.join(packageSrcPath, 'test-module-two'), path.join(packagesPath, 'test-module-two'))
    wrench.copyDirSyncRecursive(path.join(packageSrcPath, 'test-module-three'), path.join(packagesPath, 'test-module-three'))

    runs ->
      recrue.run(['disable', 'test-module-two', 'not-installed', 'test-module-three'], callback)

    waitsFor 'waiting for disable to complete', ->
      callback.callCount > 0

    runs ->
      expect(console.log).toHaveBeenCalled()
      expect(console.log.argsForCall[0][0]).toMatch /Not Installed:\s*not-installed/
      expect(console.log.argsForCall[1][0]).toMatch /Disabled:\s*test-module-two/

      config = CSON.readFileSync(configFilePath)
      expect(config).toEqual '*':
        core:
          disabledPackages: [
            "test-module"
            "test-module-two"
            "test-module-three"
          ]

  it 'does nothing if a package is already disabled', ->
    soldatHome = temp.mkdirSync('recrue-home-dir-')
    process.env.SOLDAT_HOME = soldatHome
    callback = jasmine.createSpy('callback')
    configFilePath = path.join(soldatHome, 'config.cson')

    CSON.writeFileSync configFilePath, '*':
      core:
        disabledPackages: [
          "vim-mode"
          "file-icons"
          "metrics"
          "exception-reporting"
        ]

    runs ->
      recrue.run(['disable', 'vim-mode', 'metrics'], callback)

    waitsFor 'waiting for disable to complete', ->
      callback.callCount > 0

    runs ->
      config = CSON.readFileSync(configFilePath)
      expect(config).toEqual '*':
        core:
          disabledPackages: [
            "vim-mode"
            "file-icons"
            "metrics"
            "exception-reporting"
          ]

  it 'produces an error if config.cson doesn\'t exist', ->
    soldatHome = temp.mkdirSync('recrue-home-dir-')
    process.env.SOLDAT_HOME = soldatHome
    callback = jasmine.createSpy('callback')

    runs ->
      recrue.run(['disable', 'vim-mode'], callback)

    waitsFor 'waiting for disable to complete', ->
      callback.callCount > 0

    runs ->
      expect(console.error).toHaveBeenCalled()
      expect(console.error.argsForCall[0][0].length).toBeGreaterThan 0

  it 'complains if user supplies no packages', ->
    soldatHome = temp.mkdirSync('recrue-home-dir-')
    process.env.SOLDAT_HOME = soldatHome
    callback = jasmine.createSpy('callback')

    runs ->
      recrue.run(['disable'], callback)

    waitsFor 'waiting for disable to complete', ->
      callback.callCount > 0

    runs ->
      expect(console.error).toHaveBeenCalled()
      expect(console.error.argsForCall[0][0].length).toBeGreaterThan 0
