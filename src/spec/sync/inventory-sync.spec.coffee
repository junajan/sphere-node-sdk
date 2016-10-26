{InventorySync} = require '../../lib/main'

describe 'InventorySync', ->

  beforeEach ->
    @sync = new InventorySync

  afterEach ->
    @sync = null

  describe ':: config', ->

    it 'should build white/black-listed actions update', ->
      opts = [
        {type: 'quantity', group: 'white'}
        {type: 'expectedDelivery', group: 'black'}
      ]
      newInventory =
        id: '123'
        quantityOnStock: 2
        version: 1
      oldInventory =
        id: '123'
        quantityOnStock: 10
        version: 1
      spyOn(@sync._utils, 'actionsMapSingleValue').andReturn [{
        action: 'setExpectedDelivery',
        expectedDelivery: "2001-09-11T14:00:00.000Z"
      }]
      update = @sync.config(opts).buildActions(newInventory, oldInventory).getUpdatePayload()
      expected_update =
        actions: [
          { action: 'removeQuantity', quantity: 8 }
        ]
        version: oldInventory.version
      expect(update).toEqual expected_update


  describe ':: buildActions', ->

    it 'no differences', ->
      ie =
        id: 'abc'
        sku: '123'
        quantityOnStock: 7
      update = @sync.buildActions(ie, ie).getUpdatePayload()
      expect(update).toBeUndefined()
      updateId = @sync.buildActions(ie, ie).getUpdateId()
      expect(updateId).toBe 'abc'

    it 'more quantity', ->
      ieNew =
        sku: '123'
        quantityOnStock: 77
      ieOld =
        sku: '123'
        quantityOnStock: 9
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'addQuantity'
      expect(update.actions[0].quantity).toBe 68

    it 'less quantity', ->
      ieNew =
        sku: '123'
        quantityOnStock: 7
      ieOld =
        sku: '123'
        quantityOnStock: 9
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'removeQuantity'
      expect(update.actions[0].quantity).toBe 2


    describe 'restockableInDays', ->

      it 'should add restockableInDays', ->
        ieNew =
          sku: 'xyz'
          quantityOnStock: 9
          restockableInDays: 13
        ieOld =
          sku: 'xyz'
          quantityOnStock: 9

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update).toBeDefined()
        expect(update.actions[0].action).toBe 'setRestockableInDays'
        expect(update.actions[0].restockableInDays).toBe 13

      it 'should update restockableInDays', ->
        ieNew =
          sku: 'abc'
          quantityOnStock: 0
          restockableInDays: 13
        ieOld =
          sku: 'abc'
          quantityOnStock: 0
          restockableInDays: 37

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update).toBeDefined()
        expect(update.actions[0].action).toBe 'setRestockableInDays'
        expect(update.actions[0].restockableInDays).toBe 13

      it 'should remove restockableInDays', ->
        ieNew =
          sku: 'abc'
          quantityOnStock: 0
        ieOld =
          sku: 'abc'
          quantityOnStock: 0
          restockableInDays: 37

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update).toBeDefined()
        expect(update.actions[0].action).toBe 'setRestockableInDays'
        expect(update.actions[0].restockableInDays).toBeUndefined()


    it 'should add expectedDelivery', ->
      ieNew =
        sku: 'xyz'
        quantityOnStock: 9
        expectedDelivery: '2014-01-01T01:02:03'
      ieOld =
        sku: 'xyz'
        quantityOnStock: 9
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setExpectedDelivery'
      expect(update.actions[0].expectedDelivery).toBe '2014-01-01T01:02:03'

    it 'should update expectedDelivery', ->
      ieNew =
        sku: 'abc'
        quantityOnStock: 0
        expectedDelivery: '2000'
      ieOld =
        sku: 'abc'
        quantityOnStock: 0
        expectedDelivery: '1999'
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setExpectedDelivery'
      expect(update.actions[0].expectedDelivery).toBe '2000'

    it 'should remove expectedDelivery', ->
      ieNew =
        sku: 'abc'
        quantityOnStock: 0
      ieOld =
        sku: 'abc'
        quantityOnStock: 0
        expectedDelivery: '1999'
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setExpectedDelivery'
      expect(update.actions[0].expectedDelivery).toBeUndefined()


    describe 'supplyChannel', ->

      it 'should add supplyChannel', ->
        ieNew =
          sku: 'xyz'
          quantityOnStock: 9
          supplyChannel: {
            typeId: 'channel',
            id: 1001
          }
        ieOld =
          sku: 'xyz'
          quantityOnStock: 9

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update).toBeDefined()
        expect(update.actions[0].action).toBe 'setSupplyChannel'
        expect(update.actions[0].supplyChannel.id).toBe 1001

      it 'should update supplyChannel', ->
        ieNew =
          sku: 'abc'
          quantityOnStock: 0
          supplyChannel: {
            typeId: 'channel',
            id: 1001
          }
        ieOld =
          sku: 'abc'
          quantityOnStock: 0
          supplyChannel: {
            typeId: 'channel',
            id: 8077
          }

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update).toBeDefined()
        expect(update.actions[0].action).toBe 'setSupplyChannel'
        expect(update.actions[0].supplyChannel.id).toBe 1001

      it 'should remove supplyChannel', ->
        ieNew =
          sku: 'abc'
          quantityOnStock: 0
        ieOld =
          sku: 'abc'
          quantityOnStock: 0
          supplyChannel: {
            typeId: 'channel',
            id: 8077
          }

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update).toBeDefined()
        expect(update.actions[0].action).toBe 'setSupplyChannel'
        expect(update.actions[0].supplyChannel).toBeUndefined()


    describe 'actionsMapCustom', ->
      ieNew =
        sku: 'abc'
        custom: {
          type: {
            typeId: 'type',
            id: '123'
          },
          fields: {
            nac: 'ho'
          }
        }

      it 'should set new custom type and fields', ->
        ieOld =
          sku: 'abc'
          custom: {}

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update.actions[0].action).toBe 'setCustomType'
        expect(update.actions[0].type).toEqual { typeId: 'type', id: '123' }
        expect(update.actions[0].fields).toEqual { nac: 'ho' }

      it 'should update custom type', ->
        ieOld =
          sku: 'abc'
          custom: {
            type: {
              typeId: 'type',
              id: '000'
            }
          }

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update.actions[0].action).toBe 'setCustomType'
        expect(update.actions[0].type).toEqual { typeId: 'type', id: '123' }

      it 'should update custom fields', ->
        ieOld =
          sku: 'abc'
          custom: {
            type: {
              typeId: 'type',
              id: '123'
            },
            fields: {
              nac: 'choo'
            }
          }

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update.actions[0].action).toBe 'setCustomField'
        expect(update.actions[0].name).toBe 'nac'
        expect(update.actions[0].value).toBe 'ho'
