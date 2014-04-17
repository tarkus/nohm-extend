should = require 'should'
Redism = require 'redism'
Record = require '../lib/record'

describe 'Nohm model on redism should be extended', ->

  before (done) ->
    Record.configure
      redis: new Redism
      connect: ->
        Record.model 'ExtendedModel',
          properties:
            name:
              type: 'string'
              index: true
            date:
              type: 'timestamp'
              index: true
        done()

  it 'when it was extended by record', (done) ->
      ExtendedModel = Record.getModel 'ExtendedModel'

      instance = new ExtendedModel
      instance.should.be.an.instanceof ExtendedModel
      ExtendedModel.should.have.property 'count'
      ExtendedModel.should.have.property 'get'
      ExtendedModel.count (error, count) ->
        count.should.eql 0
        try
          ExtendedModel.sort field: 'name'
        catch e
          e.toString().should.equal "Error: cannot sort on non-numeric fields with redism"

        ExtendedModel.sort field: 'date', (error, ids) ->
          should.not.exists error
          ids.length.should.equal 0
          done()
