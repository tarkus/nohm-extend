// Generated by CoffeeScript 1.7.1
(function() {
  var MyNohm, Nohm, NohmExtend,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Nohm = require('nohm').Nohm;

  NohmExtend = require('../lib/nohm-extend');

  MyNohm = (function(_super) {
    __extends(MyNohm, _super);

    function MyNohm() {
      return MyNohm.__super__.constructor.apply(this, arguments);
    }

    MyNohm["extends"] = {
      dummy: function() {}
    };

    MyNohm.methods = {
      saveMyDay: function() {}
    };

    return MyNohm;

  })(NohmExtend);

  module.exports = MyNohm;

}).call(this);
