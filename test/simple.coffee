should = require 'should'
{Nohm} = require 'nohm'
NohmExtend = require '../lib/nohm-extend'
MyNohm = require './mynohm'
redisClient = require('redis').createClient()


ExtendedModel = NohmExtend.model 'ExtendedModel',
  properties:
    name:
      type: 'string'

  client: redisClient

InheritedExtendedModel = MyNohm.model 'InheritedExtendedModel',
  properties:
    name:
      type: 'string'
    address:
      type: 'string'

  client: redisClient



describe 'Nohm model should be extended', ->

  it 'when it was extended by nohm-extend', (done) ->
    #instance = Nohm.factory 'ExtendedModel'
    instance = new ExtendedModel
    instance.should.be.an.instanceof Nohm
    ExtendedModel.should.have.property 'count'
    ExtendedModel.should.have.property 'loadSome'
    done()

  it 'when it was extended by a subclass of nohm-extend', (done) ->
    instance = Nohm.factory 'InheritedExtendedModel'
    instance.should.be.an.instanceof Nohm
    InheritedExtendedModel.should.have.an.property 'dummy'
    instance.should.have.an.property 'saveMyDay'
    done()
