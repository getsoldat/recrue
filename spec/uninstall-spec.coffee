path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
recrue = require '../lib/recrue-cli'

describe 'recrue uninstall', ->
  beforeEach ->
    silenceOutput()
    spyOnToken()
    process.env.SOLDAT_API_URL = 'http://localhost:5432'

  describe 'when no package is specified', ->
    it 'logs an error and exits', ->
      callback = jasmine.createSpy('callback')
      recrue.run(['uninstall'], callback)

      waitsFor 'waiting for command to complete', ->
        callback.callCount > 0

      runs ->
        expect(console.error.mostRecentCall.args[0].length).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).not.toBeUndefined()

  describe 'when the package is not installed', ->
    it 'ignores the package', ->
      callback = jasmine.createSpy('callback')
      recrue.run(['uninstall', 'a-package-that-does-not-exist'], callback)

      waitsFor 'waiting for command to complete', ->
        callback.callCount > 0

      runs ->
        expect(console.error.callCount).toBe 1

  describe 'when the package is installed', ->
    it 'deletes the package', ->
      soldatHome = temp.mkdirSync('recrue-home-dir-')
      packagePath = path.join(soldatHome, 'packages', 'test-package')
      fs.makeTreeSync(path.join(packagePath, 'lib'))
      fs.writeFileSync(path.join(packagePath, 'package.json'), "{}")
      process.env.SOLDAT_HOME = soldatHome

      expect(fs.existsSync(packagePath)).toBeTruthy()
      callback = jasmine.createSpy('callback')
      recrue.run(['uninstall', 'test-package'], callback)

      waitsFor 'waiting for command to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(packagePath)).toBeFalsy()

    describe "--dev", ->
      it "deletes the packages from the dev packages folder", ->
        soldatHome = temp.mkdirSync('recrue-home-dir-')
        packagePath = path.join(soldatHome, 'packages', 'test-package')
        fs.makeTreeSync(path.join(packagePath, 'lib'))
        fs.writeFileSync(path.join(packagePath, 'package.json'), "{}")
        devPackagePath = path.join(soldatHome, 'dev', 'packages', 'test-package')
        fs.makeTreeSync(path.join(devPackagePath, 'lib'))
        fs.writeFileSync(path.join(devPackagePath, 'package.json'), "{}")
        process.env.SOLDAT_HOME = soldatHome

        expect(fs.existsSync(packagePath)).toBeTruthy()
        callback = jasmine.createSpy('callback')
        recrue.run(['uninstall', 'test-package', '--dev'], callback)

        waitsFor 'waiting for command to complete', ->
          callback.callCount > 0

        runs ->
          expect(fs.existsSync(devPackagePath)).toBeFalsy()
          expect(fs.existsSync(packagePath)).toBeTruthy()

    describe "--hard", ->
      it "deletes the packages from the both packages folders", ->
        soldatHome = temp.mkdirSync('recrue-home-dir-')
        packagePath = path.join(soldatHome, 'packages', 'test-package')
        fs.makeTreeSync(path.join(packagePath, 'lib'))
        fs.writeFileSync(path.join(packagePath, 'package.json'), "{}")
        devPackagePath = path.join(soldatHome, 'dev', 'packages', 'test-package')
        fs.makeTreeSync(path.join(devPackagePath, 'lib'))
        fs.writeFileSync(path.join(devPackagePath, 'package.json'), "{}")
        process.env.SOLDAT_HOME = soldatHome

        expect(fs.existsSync(packagePath)).toBeTruthy()
        callback = jasmine.createSpy('callback')
        recrue.run(['uninstall', 'test-package', '--hard'], callback)

        waitsFor 'waiting for command to complete', ->
          callback.callCount > 0

        runs ->
          expect(fs.existsSync(devPackagePath)).toBeFalsy()
          expect(fs.existsSync(packagePath)).toBeFalsy()
