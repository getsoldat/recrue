child_process = require 'child_process'
fs = require 'fs'
path = require 'path'
temp = require 'temp'
recrue = require '../lib/recrue-cli'

describe "recrue test", ->
  [specPath] = []

  beforeEach ->
    silenceOutput()
    spyOnToken()

    currentDir = temp.mkdirSync('recrue-init-')
    spyOn(process, 'cwd').andReturn(currentDir)
    specPath = path.join(currentDir, 'spec')

  it "calls soldat to test", ->
    soldatSpawn = spyOn(child_process, 'spawn').andReturn
      stdout:
        on: ->
      stderr:
        on: ->
      on: ->
    recrue.run(['test'])

    waitsFor 'waiting for test to complete', ->
      soldatSpawn.callCount is 1

    runs ->
      if process.platform is 'win32'
        expect(soldatSpawn.mostRecentCall.args[1][2].indexOf('soldat')).not.toBe -1
        expect(soldatSpawn.mostRecentCall.args[1][2].indexOf('--dev')).not.toBe -1
        expect(soldatSpawn.mostRecentCall.args[1][2].indexOf('--test')).not.toBe -1
      else
        expect(soldatSpawn.mostRecentCall.args[0]).toEqual 'soldat'
        expect(soldatSpawn.mostRecentCall.args[1][0]).toEqual '--dev'
        expect(soldatSpawn.mostRecentCall.args[1][1]).toEqual '--test'
        expect(soldatSpawn.mostRecentCall.args[1][2]).toEqual specPath
        expect(soldatSpawn.mostRecentCall.args[2].streaming).toBeTruthy()

  describe 'returning', ->
    [callback] = []

    returnWithCode = (type, code) ->
      callback = jasmine.createSpy('callback')
      soldatReturnFn = (e, fn) -> fn(code) if e is type
      spyOn(child_process, 'spawn').andReturn
        stdout:
          on: ->
        stderr:
          on: ->
        on: soldatReturnFn
        removeListener: -> # no op
      recrue.run(['test'], callback)

    describe 'successfully', ->
      beforeEach -> returnWithCode('close', 0)

      it "prints success", ->
        expect(callback).toHaveBeenCalled()
        expect(callback.mostRecentCall.args[0]).toBeUndefined()
        expect(process.stdout.write.mostRecentCall.args[0]).toEqual 'Tests passed\n'.green

    describe 'with a failure', ->
      beforeEach -> returnWithCode('close', 1)

      it "prints failure", ->
        expect(callback).toHaveBeenCalled()
        expect(callback.mostRecentCall.args[0]).toEqual 'Tests failed'

    describe 'with an error', ->
      beforeEach -> returnWithCode('error')

      it "prints failure", ->
        expect(callback).toHaveBeenCalled()
        expect(callback.mostRecentCall.args[0]).toEqual 'Tests failed'
