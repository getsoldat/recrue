path = require 'path'
temp = require 'temp'
CSON = require 'season'
recrue = require '../lib/recrue-cli'
fs = require '../lib/fs'

describe "recrue init", ->
  [packagePath, themePath] = []

  beforeEach ->
    silenceOutput()
    spyOnToken()

    currentDir = temp.mkdirSync('recrue-init-')
    spyOn(process, 'cwd').andReturn(currentDir)
    packagePath = path.join(currentDir, 'fake-package')
    themePath = path.join(currentDir, 'fake-theme')
    process.env.GITHUB_USER = 'somebody'

  describe "when creating a package", ->
    describe "when package syntax is CoffeeScript", ->
      it "generates the proper file structure", ->
        callback = jasmine.createSpy('callback')
        recrue.run(['init', '--package', 'fake-package'], callback)

        waitsFor 'waiting for init to complete', ->
          callback.callCount is 1

        runs ->
          expect(fs.existsSync(packagePath)).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'keymaps'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'keymaps', 'fake-package.cson'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'lib'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'lib', 'fake-package-view.coffee'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'lib', 'fake-package.coffee'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'menus'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'menus', 'fake-package.cson'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'spec', 'fake-package-view-spec.coffee'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'spec', 'fake-package-spec.coffee'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'styles', 'fake-package.less'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'package.json'))).toBeTruthy()
          expect(JSON.parse(fs.readFileSync(path.join(packagePath, 'package.json'))).name).toBe 'fake-package'
          expect(JSON.parse(fs.readFileSync(path.join(packagePath, 'package.json'))).repository).toBe 'https://github.com/somebody/fake-package'

    describe "when package syntax is JavaScript", ->
      it "generates the proper file structure", ->
        callback = jasmine.createSpy('callback')
        recrue.run(['init', '--syntax', 'javascript', '--package', 'fake-package'], callback)

        waitsFor 'waiting for init to complete', ->
          callback.callCount is 1

        runs ->
          expect(fs.existsSync(packagePath)).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'keymaps'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'keymaps', 'fake-package.json'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'lib'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'lib', 'fake-package-view.js'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'lib', 'fake-package.js'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'menus'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'menus', 'fake-package.json'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'spec', 'fake-package-view-spec.js'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'spec', 'fake-package-spec.js'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'styles', 'fake-package.less'))).toBeTruthy()
          expect(fs.existsSync(path.join(packagePath, 'package.json'))).toBeTruthy()
          expect(JSON.parse(fs.readFileSync(path.join(packagePath, 'package.json'))).name).toBe 'fake-package'
          expect(JSON.parse(fs.readFileSync(path.join(packagePath, 'package.json'))).repository).toBe 'https://github.com/somebody/fake-package'

  describe "when creating a theme", ->
    it "generates the proper file structure", ->
      callback = jasmine.createSpy('callback')
      recrue.run(['init', '--theme', 'fake-theme'], callback)

      waitsFor 'waiting for init to complete', ->
        callback.callCount is 1

      runs ->
        expect(fs.existsSync(themePath)).toBeTruthy()
        expect(fs.existsSync(path.join(themePath, 'styles'))).toBeTruthy()
        expect(fs.existsSync(path.join(themePath, 'styles', 'base.less'))).toBeTruthy()
        expect(fs.existsSync(path.join(themePath, 'styles', 'syntax-variables.less'))).toBeTruthy()
        expect(fs.existsSync(path.join(themePath, 'index.less'))).toBeTruthy()
        expect(fs.existsSync(path.join(themePath, 'README.md'))).toBeTruthy()
        expect(fs.existsSync(path.join(themePath, 'package.json'))).toBeTruthy()
        expect(JSON.parse(fs.readFileSync(path.join(themePath, 'package.json'))).name).toBe 'fake-theme'
        expect(JSON.parse(fs.readFileSync(path.join(themePath, 'package.json'))).repository).toBe 'https://github.com/somebody/fake-theme'
