path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
express = require 'express'
http = require 'http'
recrue = require '../lib/recrue-cli'

describe 'recrue publish', ->
  [server] = []

  beforeEach ->
    spyOnToken()
    silenceOutput()

    app = express()
    server =  http.createServer(app)
    server.listen(3000)

    soldatHome = temp.mkdirSync('recrue-home-dir-')
    process.env.SOLDAT_HOME = soldatHome
    process.env.SOLDAT_API_URL = "http://localhost:3000/api"
    process.env.SOLDAT_RESOURCE_PATH = temp.mkdirSync('soldat-resource-path-')

  afterEach ->
    server.close()

  it "validates the package's package.json file", ->
    packageToPublish = temp.mkdirSync('recrue-test-package-')
    fs.writeFileSync(path.join(packageToPublish, 'package.json'), '}{')
    process.chdir(packageToPublish)
    callback = jasmine.createSpy('callback')
    recrue.run(['publish'], callback)

    waitsFor 'waiting for publish to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0].message).toBe 'Error parsing package.json file: Unexpected token } in JSON at position 0'

  it "validates the package is in a Git repository", ->
    packageToPublish = temp.mkdirSync('recrue-test-package-')
    metadata =
      name: 'test'
      version: '1.0.0'
    fs.writeFileSync(path.join(packageToPublish, 'package.json'), JSON.stringify(metadata))
    process.chdir(packageToPublish)
    callback = jasmine.createSpy('callback')
    recrue.run(['publish'], callback)

    waitsFor 'waiting for publish to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0].message).toBe 'Package must be in a Git repository before publishing: https://help.github.com/articles/create-a-repo'

  it "validates the engines.soldat range in the package.json file", ->
    packageToPublish = temp.mkdirSync('recrue-test-package-')
    metadata =
      name: 'test'
      version: '1.0.0'
      engines:
        soldat: '><>'
    fs.writeFileSync(path.join(packageToPublish, 'package.json'), JSON.stringify(metadata))
    process.chdir(packageToPublish)
    callback = jasmine.createSpy('callback')
    recrue.run(['publish'], callback)

    waitsFor 'waiting for publish to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0].message).toBe 'The Soldat engine range in the package.json file is invalid: ><>'

  it "validates the dependency semver ranges in the package.json file", ->
    packageToPublish = temp.mkdirSync('recrue-test-package-')
    metadata =
      name: 'test'
      version: '1.0.0'
      engines:
        soldat: '1'
      dependencies:
        abc: 'git://github.com/user/project.git'
        abcd: 'latest'
        foo: '^^'
    fs.writeFileSync(path.join(packageToPublish, 'package.json'), JSON.stringify(metadata))
    process.chdir(packageToPublish)
    callback = jasmine.createSpy('callback')
    recrue.run(['publish'], callback)

    waitsFor 'waiting for publish to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0].message).toBe 'The foo dependency range in the package.json file is invalid: ^^'

  it "validates the dev dependency semver ranges in the package.json file", ->
    packageToPublish = temp.mkdirSync('recrue-test-package-')
    metadata =
      name: 'test'
      version: '1.0.0'
      engines:
        soldat: '1'
      dependencies:
        foo: '^5'
      devDependencies:
        abc: 'git://github.com/user/project.git'
        abcd: 'latest'
        bar: '1,3'
    fs.writeFileSync(path.join(packageToPublish, 'package.json'), JSON.stringify(metadata))
    process.chdir(packageToPublish)
    callback = jasmine.createSpy('callback')
    recrue.run(['publish'], callback)

    waitsFor 'waiting for publish to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0].message).toBe 'The bar dev dependency range in the package.json file is invalid: 1,3'
