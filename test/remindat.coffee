process.env.TZ = 'UTC'

sinon  = require 'sinon'
assert = require 'power-assert'
Helper = require 'hubot-test-helper'
helper = new Helper('../scripts')

describe 'ReminderAt Hubot', ->
  room = null

  beforeEach ->
    room = helper.createRoom()

  context 'formats', ->

    it 'chrono formats specified with "at" are parsed', ->
      # Example taken from http://wanasit.github.io/pages/chrono/
      room.user.say 'user', 'hubot remind me at Saturday, 17 August 2513 to do task'
      assert.deepEqual room.messages[1], [
        "hubot", "I'll remind you to do task at Thu Aug 17 2513 12:00:00 GMT+0000 (UTC)"
      ]

  context 'queue', ->

    it 'not over max', (done) ->

      @timeout(0)

      d = new Date()
      d.setSeconds(d.getSeconds() + 5)

      room.user.say 'user', "hubot remind me at #{d.toString()} to do task"
      assert.deepEqual room.messages, [
        [ "user", "hubot remind me at #{d.toString()} to do task" ]
        [ "hubot", "I'll remind you to do task at #{d.toString()}" ]
      ]

      setTimeout =>
        assert.deepEqual room.messages, [
          [ "user", "hubot remind me at #{d.toString()} to do task" ]
          [ "hubot", "I'll remind you to do task at #{d.toString()}" ]
        ]
      , 4000

      setTimeout =>
        assert.deepEqual room.messages, [
          [ "user", "hubot remind me at #{d.toString()} to do task" ]
          [ "hubot", "I'll remind you to do task at #{d.toString()}" ]
          [ "hubot", "@user you asked me to remind you to do task" ]
        ]
        done()
      , 6000

    it 'over max case', (done) ->

      @timeout(0)

      clock = sinon.useFakeTimers()
      max = 2147483647 # 24 days

      d = new Date()
      d.setDate(d.getDate() + 25) # remind over max

      room.user.say 'user', "hubot remind me at #{d.toString()} to do task"
      assert.deepEqual room.messages, [
        [ "user", "hubot remind me at #{d.toString()} to do task" ]
        [ "hubot", "I'll remind you to do task at #{d.toString()}" ]
      ]

      setTimeout =>
        assert.deepEqual room.messages, [
          [ "user", "hubot remind me at #{d.toString()} to do task" ]
          [ "hubot", "I'll remind you to do task at #{d.toString()}" ]
        ]
        # forward 1 day
        clock.tick(1000 * 60 * 60 * 24)
      , max

      setTimeout =>
        assert.deepEqual room.messages, [
          [ "user", "hubot remind me at #{d.toString()} to do task" ]
          [ "hubot", "I'll remind you to do task at #{d.toString()}" ]
          [ "hubot", "@user you asked me to remind you to do task" ]
        ]
        clock.restore()
        done()
      , max + (1000 * 60 * 60 * 24)

      clock.tick(max + 10)
