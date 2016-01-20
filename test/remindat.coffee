process.env.TZ = 'UTC'

sinon  = require 'sinon'
assert = require 'power-assert'
Helper = require 'hubot-test-helper'
helper = new Helper('../scripts')
co     = require 'co'

describe 'ReminderAt Hubot', ->

  beforeEach ->
    @room = helper.createRoom(httpd: false)

  context 'formats', ->

    beforeEach ->
      co =>
        yield @room.user.say 'user', 'hubot remind me at Saturday, 17 August 2513 to do task'

    it 'chrono formats specified with "at" are parsed', ->
      # Example taken from http://wanasit.github.io/pages/chrono/
      d = new Date("2513-08-17 12:00:00")
      assert.deepEqual @room.messages[1], [
        "hubot", "I'll remind you to do task at #{d.toLocaleString()}"
      ]

  context 'not over max', ->

    beforeEach ->

      @d = new Date()
      @d.setSeconds(@d.getSeconds() + 5)
      co =>
        yield @room.user.say 'user', "hubot remind me at #{@d.toString()} to do task"

    it 'should got correct messages', (done) ->

      @timeout(0)

      assert.deepEqual @room.messages, [
        [ "user", "hubot remind me at #{@d.toString()} to do task" ]
        [ "hubot", "I'll remind you to do task at #{@d.toLocaleString()}" ]
      ]

      setTimeout =>
        assert.deepEqual @room.messages, [
          [ "user", "hubot remind me at #{@d.toString()} to do task" ]
          [ "hubot", "I'll remind you to do task at #{@d.toLocaleString()}" ]
        ]
      , 4000

      setTimeout =>
        assert.deepEqual @room.messages, [
          [ "user", "hubot remind me at #{@d.toString()} to do task" ]
          [ "hubot", "I'll remind you to do task at #{@d.toLocaleString()}" ]
          [ "hubot", "@user you asked me to remind you to do task" ]
        ]
        done()
      , 6000

  context 'over max case', ->

    beforeEach ->
      @clock = sinon.useFakeTimers()
      @max = 2147483647 # 24 days

      @d = new Date()
      @d.setDate(@d.getDate() + 25) # remind over max

      co =>
        yield @room.user.say 'user', "hubot remind me at #{@d.toString()} to do task"

    it 'over max case', (done) ->

      @timeout(0)

      assert.deepEqual @room.messages, [
        [ "user", "hubot remind me at #{@d.toString()} to do task" ]
        [ "hubot", "I'll remind you to do task at #{@d.toLocaleString()}" ]
      ]

      setTimeout =>
        assert.deepEqual @room.messages, [
          [ "user", "hubot remind me at #{@d.toString()} to do task" ]
          [ "hubot", "I'll remind you to do task at #{@d.toLocaleString()}" ]
        ]
        # forward 1 day
        @clock.tick(1000 * 60 * 60 * 24)
      , @max

      setTimeout =>
        assert.deepEqual @room.messages, [
          [ "user", "hubot remind me at #{@d.toString()} to do task" ]
          [ "hubot", "I'll remind you to do task at #{@d.toLocaleString()}" ]
          [ "hubot", "@user you asked me to remind you to do task" ]
        ]
        @clock.restore()
        done()
      , @max + (1000 * 60 * 60 * 24)

      @clock.tick(@max + 10)
