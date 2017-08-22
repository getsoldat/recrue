fs = require 'fs'
path = require 'path'
temp = require 'temp'
recrue = require '../lib/recrue-cli'

describe 'recrue link/unlink', ->
  beforeEach ->
    silenceOutput()
    spyOnToken()

  describe "when the dev flag is false (the default)", ->
    it 'symlinks packages to $SOLDAT_HOME/packages', ->
      soldatHome = temp.mkdirSync('recrue-home-dir-')
      process.env.SOLDAT_HOME = soldatHome
      packageToLink = temp.mkdirSync('a-package-')
      process.chdir(packageToLink)
      callback = jasmine.createSpy('callback')

      runs ->
        recrue.run(['link'], callback)

      waitsFor 'waiting for link to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(packageToLink)))).toBeTruthy()
        expect(fs.realpathSync(path.join(soldatHome, 'packages', path.basename(packageToLink)))).toBe fs.realpathSync(packageToLink)

        callback.reset()
        recrue.run(['unlink'], callback)

      waitsFor 'waiting for unlink to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(packageToLink)))).toBeFalsy()

  describe "when the dev flag is true", ->
    it 'symlinks packages to $SOLDAT_HOME/dev/packages', ->
      soldatHome = temp.mkdirSync('recrue-home-dir-')
      process.env.SOLDAT_HOME = soldatHome
      packageToLink = temp.mkdirSync('a-package-')
      process.chdir(packageToLink)
      callback = jasmine.createSpy('callback')

      runs ->
        recrue.run(['link', '--dev'], callback)

      waitsFor 'waiting for link to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(path.join(soldatHome, 'dev', 'packages', path.basename(packageToLink)))).toBeTruthy()
        expect(fs.realpathSync(path.join(soldatHome, 'dev', 'packages', path.basename(packageToLink)))).toBe fs.realpathSync(packageToLink)

        callback.reset()
        recrue.run(['unlink', '--dev'], callback)

      waitsFor 'waiting for unlink to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(path.join(soldatHome, 'dev', 'packages', path.basename(packageToLink)))).toBeFalsy()

  describe "when the hard flag is true", ->
    it "unlinks the package from both $SOLDAT_HOME/packages and $SOLDAT_HOME/dev/packages", ->
      soldatHome = temp.mkdirSync('recrue-home-dir-')
      process.env.SOLDAT_HOME = soldatHome
      packageToLink = temp.mkdirSync('a-package-')
      process.chdir(packageToLink)
      callback = jasmine.createSpy('callback')

      runs ->
        recrue.run(['link', '--dev'], callback)

      waitsFor 'link --dev to complete', ->
        callback.callCount is 1

      runs ->
        recrue.run(['link'], callback)

      waitsFor 'link to complete', ->
        callback.callCount is 2

      runs ->
        recrue.run(['unlink', '--hard'], callback)

      waitsFor 'unlink --hard to complete', ->
        callback.callCount is 3

      runs ->
        expect(fs.existsSync(path.join(soldatHome, 'dev', 'packages', path.basename(packageToLink)))).toBeFalsy()
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(packageToLink)))).toBeFalsy()

  describe "when the all flag is true", ->
    it "unlinks all packages in $SOLDAT_HOME/packages and $SOLDAT_HOME/dev/packages", ->
      soldatHome = temp.mkdirSync('recrue-home-dir-')
      process.env.SOLDAT_HOME = soldatHome
      packageToLink1 = temp.mkdirSync('a-package-')
      packageToLink2 = temp.mkdirSync('a-package-')
      packageToLink3 = temp.mkdirSync('a-package-')
      callback = jasmine.createSpy('callback')

      runs ->
        recrue.run(['link', '--dev', packageToLink1], callback)

      waitsFor 'link --dev to complete', ->
        callback.callCount is 1

      runs ->
        callback.reset()
        recrue.run(['link', packageToLink2], callback)
        recrue.run(['link', packageToLink3], callback)

      waitsFor 'link to complee', ->
        callback.callCount is 2

      runs ->
        callback.reset()
        expect(fs.existsSync(path.join(soldatHome, 'dev', 'packages', path.basename(packageToLink1)))).toBeTruthy()
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(packageToLink2)))).toBeTruthy()
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(packageToLink3)))).toBeTruthy()
        recrue.run(['unlink', '--all'], callback)

      waitsFor 'unlink --all to complete', ->
        callback.callCount is 1

      runs ->
        expect(fs.existsSync(path.join(soldatHome, 'dev', 'packages', path.basename(packageToLink1)))).toBeFalsy()
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(packageToLink2)))).toBeFalsy()
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(packageToLink3)))).toBeFalsy()

  describe "when the package name is numeric", ->
    it "still links and unlinks normally", ->
      soldatHome = temp.mkdirSync('recrue-home-dir-')
      process.env.SOLDAT_HOME = soldatHome
      numericPackageName = temp.mkdirSync('42')
      callback = jasmine.createSpy('callback')

      runs ->
        recrue.run(['link', numericPackageName], callback)

      waitsFor 'link to complete', ->
        callback.callCount is 1

      runs ->
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(numericPackageName)))).toBeTruthy()
        expect(fs.realpathSync(path.join(soldatHome, 'packages', path.basename(numericPackageName)))).toBe fs.realpathSync(numericPackageName)

        callback.reset()
        recrue.run(['unlink', numericPackageName], callback)

      waitsFor 'unlink to complete', ->
        callback.callCount is 1

      runs ->
        expect(fs.existsSync(path.join(soldatHome, 'packages', path.basename(numericPackageName)))).toBeFalsy()
