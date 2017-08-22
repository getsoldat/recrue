path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
recrue = require '../lib/recrue-cli'

describe "recrue develop", ->
  [repoPath, linkedRepoPath] = []

  beforeEach ->
    silenceOutput()
    spyOnToken()

    soldatHome = temp.mkdirSync('recrue-home-dir-')
    process.env.SOLDAT_HOME = soldatHome

    soldatReposHome = temp.mkdirSync('recrue-repos-home-dir-')
    process.env.SOLDAT_REPOS_HOME = soldatReposHome

    repoPath = path.join(soldatReposHome, 'fake-package')
    linkedRepoPath = path.join(soldatHome, 'dev', 'packages', 'fake-package')

  describe "when the package doesn't have a published repository url", ->
    it "logs an error", ->
      Develop = require '../lib/develop'
      spyOn(Develop.prototype, "getRepositoryUrl").andCallFake (packageName, callback) ->
        callback("Here is the error")

      callback = jasmine.createSpy('callback')
      recrue.run(['develop', "fake-package"], callback)

      waitsFor 'waiting for develop to complete', ->
        callback.callCount is 1

      runs ->
        expect(callback.mostRecentCall.args[0]).toBe "Here is the error"
        expect(fs.existsSync(repoPath)).toBeFalsy()
        expect(fs.existsSync(linkedRepoPath)).toBeFalsy()

  describe "when the repository hasn't been cloned", ->
    it "clones the repository to SOLDAT_REPOS_HOME and links it to SOLDAT_HOME/dev/packages", ->
      Develop = require '../lib/develop'
      spyOn(Develop.prototype, "getRepositoryUrl").andCallFake (packageName, callback) ->
        repoUrl = path.join(__dirname, 'fixtures', 'repo.git')
        callback(null, repoUrl)
      spyOn(Develop.prototype, "installDependencies").andCallFake (packageDirectory, options) ->
        @linkPackage(packageDirectory, options)

      callback = jasmine.createSpy('callback')
      recrue.run(['develop', "fake-package"], callback)

      waitsFor 'waiting for develop to complete', ->
        callback.callCount is 1

      runs ->
        expect(callback.mostRecentCall.args[0]).toBeFalsy()
        expect(fs.existsSync(repoPath)).toBeTruthy()
        expect(fs.existsSync(path.join(repoPath, 'Syntaxes', 'Makefile.plist'))).toBeTruthy()
        expect(fs.existsSync(linkedRepoPath)).toBeTruthy()
        expect(fs.realpathSync(linkedRepoPath)).toBe fs.realpathSync(repoPath)

  describe "when the repository has already been cloned", ->
    it "links it to SOLDAT_HOME/dev/packages", ->
      fs.makeTreeSync(repoPath)
      fs.writeFileSync(path.join(repoPath, "package.json"), "")
      callback = jasmine.createSpy('callback')
      recrue.run(['develop', "fake-package"], callback)

      waitsFor 'waiting for develop to complete', ->
        callback.callCount is 1

      runs ->
        expect(callback.mostRecentCall.args[0]).toBeFalsy()
        expect(fs.existsSync(repoPath)).toBeTruthy()
        expect(fs.existsSync(linkedRepoPath)).toBeTruthy()
        expect(fs.realpathSync(linkedRepoPath)).toBe fs.realpathSync(repoPath)
