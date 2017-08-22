path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
recrue = require '../lib/recrue-cli'

describe "recrue config", ->
  [soldatHome, userConfigPath] = []

  beforeEach ->
    spyOnToken()
    silenceOutput()

    soldatHome = temp.mkdirSync('recrue-home-dir-')
    process.env.SOLDAT_HOME = soldatHome
    userConfigPath = path.join(soldatHome, '.recruerc')

    # Make sure the cache used is the one for the test env
    delete process.env.npm_config_cache

  describe "recrue config get", ->
    it "reads the value from the global config when there is no user config", ->
      callback = jasmine.createSpy('callback')
      recrue.run(['config', 'get', 'cache'], callback)

      waitsFor 'waiting for config get to complete', 600000, ->
        callback.callCount is 1

      runs ->
        expect(process.stdout.write.argsForCall[0][0].trim()).toBe path.join(process.env.SOLDAT_HOME, '.recrue')

  describe "recrue config set", ->
    it "sets the value in the user config", ->
      expect(fs.isFileSync(userConfigPath)).toBe false

      callback = jasmine.createSpy('callback')
      recrue.run(['config', 'set', 'foo', 'bar'], callback)

      waitsFor 'waiting for config set to complete', 600000, ->
        callback.callCount is 1

      runs ->
        expect(fs.isFileSync(userConfigPath)).toBe true

        callback.reset()
        recrue.run(['config', 'get', 'foo'], callback)

      waitsFor 'waiting for config get to complete', 600000, ->
        callback.callCount is 1

      runs ->
        expect(process.stdout.write.argsForCall[0][0].trim()).toBe 'bar'
