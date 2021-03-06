BaseSync = require '../../lib/sync/base-sync'

OLD_OBJ =
  id: '123'
  foo: 'bar'
  version: 1

NEW_OBJ =
  id: '123'
  foo: 'qux'
  version: 1

describe 'BaseSync', ->

  beforeEach ->
    @sync = new BaseSync

  afterEach ->
    @sync = null

  it 'should initialize', ->
    expect(@sync).toBeDefined()
    expect(@sync._data).toEqual {}
    expect(@sync._utils).toBeDefined()
    expect(@sync._syncConfig.length).toBe 0

  describe ':: config', ->

    it 'should build all actions if config is not defined', ->
      spyOn(@sync, '_doMapActions').andReturn [{foo: 'bar'}]
      update = @sync.config().buildActions({foo: 'bar'}, {foo: 'qux', version: 1}).getUpdatePayload()
      expected_update =
        actions: [
          {foo: 'bar'}
        ]
        version: 1
      expect(update).toEqual expected_update

    it 'should throw if given group is not supported', ->
      spyOn(@sync, '_doMapActions').andCallFake (type, fn) => @sync._mapActionOrNot 'base', -> [{foo: 'bar'}]
      expect(=>
        @sync.config([{type: 'base', group: 'foo'}])
        .buildActions({foo: 'bar'}, {foo: 'qux', version: 1})
      ).toThrow new Error 'Action group \'foo\' not supported. Please use black or white.'


  describe ':: buildActions', ->

    it 'should return reference to the object', ->
      s = @sync.buildActions(NEW_OBJ, OLD_OBJ)
      expect(s).toEqual @sync

    it 'should build empty action update', ->
      update = @sync.buildActions(NEW_OBJ, OLD_OBJ).getUpdatePayload()
      expect(update).not.toBeDefined()

    it 'should throw an error if no objects to compare were given', ->
      expect(=> @sync.buildActions()).toThrow new Error 'Missing either new_obj or old_obj in order to build update actions'

  describe ':: filterActions', ->

    it 'should return reference to the object', ->
      s = @sync.filterActions()
      expect(s).toEqual @sync

    it 'should filter built actions', ->
      builtActions = ['foo', 'bar']
      spyOn(@sync, '_doMapActions').andReturn builtActions
      update = @sync.buildActions(NEW_OBJ, OLD_OBJ).filterActions (a) ->
        a isnt 'bar'
      .getUpdatePayload()
      expect(update.actions).toEqual ['foo']

    it 'should work with no difference', ->
      update = @sync.buildActions({}, {}).filterActions (a) ->
        true
      .getUpdatePayload()
      expect(update).toBeUndefined()

    it 'should set update to undefined if filter returns empty action list', ->
      builtActions = ['some', 'action']
      spyOn(@sync, '_doMapActions').andReturn builtActions
      update = @sync.buildActions(NEW_OBJ, OLD_OBJ).filterActions (a) ->
        false
      .getUpdatePayload()
      expect(update).toBeUndefined()

  xdescribe ':: shouldUpdate', ->

  xdescribe ':: getUpdateId', ->

  describe ':: getUpdateActions', ->

    it 'should return an empty array if there are no update actions', ->
      expect(@sync.getUpdateActions()).toEqual []

  xdescribe ':: getUpdatePayload', ->
