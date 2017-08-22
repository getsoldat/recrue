fs = require 'fs'
recrue = require '../lib/recrue-cli'

describe 'recrue command line interface', ->
  beforeEach ->
    silenceOutput()
    spyOnToken()

  describe 'when no arguments are present', ->
    it 'prints a usage message', ->
      recrue.run([])
      expect(console.log).not.toHaveBeenCalled()
      expect(console.error).toHaveBeenCalled()
      expect(console.error.argsForCall[0][0].length).toBeGreaterThan 0

  describe 'when the help flag is specified', ->
    it 'prints a usage message', ->
      recrue.run(['-h'])
      expect(console.log).not.toHaveBeenCalled()
      expect(console.error).toHaveBeenCalled()
      expect(console.error.argsForCall[0][0].length).toBeGreaterThan 0

  describe 'when the version flag is specified', ->
    it 'prints the version', ->
      callback = jasmine.createSpy('callback')
      recrue.run(['-v', '--no-color'], callback)

      waitsFor ->
        callback.callCount is 1

      runs ->
        expect(console.error).not.toHaveBeenCalled()
        expect(console.log).toHaveBeenCalled()
        lines = console.log.argsForCall[0][0].split('\n')
        expect(lines[0]).toBe "recrue  #{require('../package.json').version}"
        expect(lines[1]).toBe "npm  #{require('npm/package.json').version}"
        expect(lines[2]).toBe "node #{process.versions.node} #{process.arch}"

  describe 'when an unrecognized command is specified', ->
    it 'prints an error message and exits', ->
      callback = jasmine.createSpy('callback')
      recrue.run(['this-will-never-be-a-command'], callback)
      expect(console.log).not.toHaveBeenCalled()
      expect(console.error).toHaveBeenCalled()
      expect(console.error.argsForCall[0][0].length).toBeGreaterThan 0
      expect(callback.mostRecentCall.args[0]).not.toBeUndefined()
