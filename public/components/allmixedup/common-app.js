(function() {
  window.app = {};
  window.app.exports = {};
  window.app.require = function(name) {
    try {
      return window.app.exports[name];
    } catch(e) {
      console.log("NameError: '" + name + "' not found");
    }
  }
})(this);
