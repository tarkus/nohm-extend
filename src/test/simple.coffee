should = require 'should'
Record = require '../lib/record'
MyRecord = require './my_record'
redis = require('redis').createClient()

ExtendedModel = Record.model 'ExtendedModel',
  properties:
    name:
      type: 'string'
      index: true

  client: redis

InheritedExtendedModel = MyRecord.model 'InheritedExtendedModel',
  properties:
    name:
      type: 'string'
    address:
      type: 'string'

  client: redis


describe 'Nohm model should be extended', ->

  it 'when it was extended by nohm-extend', (done) ->
    instance = new ExtendedModel
    instance.should.be.an.instanceof Nohm
    ExtendedModel.should.have.property 'count'
    ExtendedModel.should.have.property 'loadSome'
    ExtendedModel.loadSome [1], (err, instances) ->
      err.should.eql 'not found'
      ExtendedModel.sort field: 'name', (err, ids) ->
        ids.should.eql []
        done()

  it 'when it was extended by subclass', (done) ->
    instance = Nohm.factory 'InheritedExtendedModel'
    instance.should.be.an.instanceof Nohm
    InheritedExtendedModel.should.have.an.property 'count'
    InheritedExtendedModel.should.have.an.property 'dummy'
    instance.should.have.an.property 'saveMyDay'
    done()
