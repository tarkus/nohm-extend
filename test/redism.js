// Generated by CoffeeScript 1.7.1
(function() {
  var Record, Redism, should;

  should = require('should');

  Redism = require('redism');

  Record = require('../lib/record');

  describe('Nohm model on redism should be extended', function() {
    before(function(done) {
      return Record.configure({
        redis: new Redism,
        connect: function() {
          Record.model('ExtendedModel', {
            properties: {
              name: {
                type: 'string',
                index: true
              },
              date: {
                type: 'timestamp',
                index: true
              }
            }
          });
          return done();
        }
      });
    });
    return it('when it was extended by record', function(done) {
      var ExtendedModel, instance;
      ExtendedModel = Record.getModel('ExtendedModel');
      instance = new ExtendedModel;
      instance.should.be.an["instanceof"](ExtendedModel);
      ExtendedModel.should.have.property('count');
      ExtendedModel.should.have.property('get');
      return ExtendedModel.count(function(error, count) {
        var e;
        count.should.eql(0);
        try {
          ExtendedModel.sort({
            field: 'name'
          });
        } catch (_error) {
          e = _error;
          e.toString().should.equal("Error: cannot sort on non-numeric fields with redism");
        }
        return ExtendedModel.sort({
          field: 'date'
        }, function(error, ids) {
          should.not.exists(error);
          ids.length.should.equal(0);
          return done();
        });
      });
    });
  });

}).call(this);
