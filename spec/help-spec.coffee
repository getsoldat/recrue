recrue = require '../lib/recrue-cli'

describe 'command help', ->
  beforeEach ->
    spyOnToken()
    silenceOutput()

  describe "recrue help publish", ->
    it "displays the help for the command", ->
      callback = jasmine.createSpy('callback')
      recrue.run(['help', 'publish'], callback)

      waitsFor 'waiting for help to complete', 60000, ->
        callback.callCount is 1

      runs ->
        expect(console.error.callCount).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).toBeUndefined()

  describe "recrue publish -h", ->
    it "displays the help for the command", ->
      callback = jasmine.createSpy('callback')
      recrue.run(['publish', '-h'], callback)

      waitsFor 'waiting for help to complete', 60000, ->
        callback.callCount is 1

      runs ->
        expect(console.error.callCount).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).toBeUndefined()

  describe "recrue help", ->
    it "displays the help for recrue", ->
      callback = jasmine.createSpy('callback')
      recrue.run(['help'], callback)

      waitsFor 'waiting for help to complete', 60000, ->
        callback.callCount is 1

      runs ->
        expect(console.error.callCount).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).toBeUndefined()

  describe "recrue", ->
    it "displays the help for recrue", ->
      callback = jasmine.createSpy('callback')
      recrue.run([], callback)

      waitsFor 'waiting for help to complete', 60000, ->
        callback.callCount is 1

      runs ->
        expect(console.error.callCount).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).toBeUndefined()
