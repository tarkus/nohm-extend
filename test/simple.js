// Generated by CoffeeScript 1.7.1
(function() {
  var Record, should;

  should = require('should');

  Record = require('../lib/record');

  describe('Nohm model should be extended', function() {
    before(function(done) {
      return Record.configure({
        redis: require('redis').createClient(),
        connect: function() {
          Record.model('ExtendedModel', {
            properties: {
              name: {
                type: 'string',
                index: true
              }
            }
          });
          return done();
        }
      });
    });
    it('when it was extended by record', function(done) {
      var ExtendedModel, instance;
      ExtendedModel = Record.getModel('ExtendedModel');
      instance = new ExtendedModel;
      instance.should.be.an["instanceof"](ExtendedModel);
      ExtendedModel.should.have.property('count');
      ExtendedModel.should.have.property('get');
      return ExtendedModel.count(function(error, count) {
        count.should.eql(0);
        return ExtendedModel.sort({
          field: 'name'
        }, function(error, ids) {
          should.not.exist(error);
          ids.length.should.be.equal(0);
          return done();
        });
      });
    });
    before(function(done) {
      return Record.configure({
        redis: require('redis').createClient(),
        connect: function() {
          Record.model('InheritedExtendedModel', {
            properties: {
              name: {
                type: 'string'
              },
              address: {
                type: 'string'
              }
            },
            "extends": {
              dummy: function() {}
            },
            methods: {
              saveMyDay: function() {}
            }
          });
          return done();
        }
      });
    });
    return it('when it was extended by subclass', function(done) {
      var InheritedExtendedModel, instance;
      InheritedExtendedModel = Record.getModel('InheritedExtendedModel');
      instance = Record.factory('InheritedExtendedModel');
      instance.should.be.an["instanceof"](InheritedExtendedModel);
      InheritedExtendedModel.should.have.an.property('count');
      InheritedExtendedModel.should.have.an.property('dummy');
      instance.should.have.an.property('saveMyDay');
      return done();
    });
  });

}).call(this);
