(function() {
  var ONE_MINUTE = 60;
  var ONE_HOUR   = ONE_MINUTE * 60;
  var ONE_DAY    = ONE_HOUR * 24;

  Vue.filter("timestring", function(ts) {
    if (!ts) return "";
    if (typeof ts == "string")
      ts = new Date(ts);

    var now       = new Date().epoch();
    var yesterday = now - (now % 86400);
    var tomorrow  = now + 86400 - (now % 86400);
    var s         = ts.epoch();

    if (s > tomorrow + 86400) return ts.getDate() + ". " + ts.getAbbrMonth() + " " + ts.getHM();
    if (s > yesterday) return ts.getHM();
    if (s > now - ONE_DAY * 31) return ts.getDate() + ". " + ts.getAbbrMonth() + " " + ts.getHM();

    return ts.getDate() + ". " + ts.getAbbrMonth() + " " + ts.getFullYear();
  });
})();
