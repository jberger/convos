(function() {
  // *foo*     or _foo_     = <em>foo</em>
  // **foo**   or __foo__   = <strong>foo</strong>
  // ***foo*** or ___foo___ = <em><strong>foo</strong></em>
  // \*foo*    or \_foo_    = *foo* or _foo_

  var codeToHtmlRe = new RegExp("(\\\\?)`([^`]+)`", "g");
  var mdToHtmlRe = new RegExp("(^|\\s)(\\\\?)(\\*+|_+)(\\w.*?)\\3", "g");
  Vue.filter("markdown", function(str) {
    str = str.replace(mdToHtmlRe, function(all, b, esc, md, text) {
      if (md.match(/^_/) && text.match(/^[A-Z]+$/)) return all; // Avoid __DATA__
      switch (md.length) {
        case 1:
          return esc ? all.replace(/^\\/, "") : b + "<em>" + text + "</em>";
        case 2:
          return esc ? all.replace(/^\\/, "") : b + "<strong>" + text + "</strong>";
        case 3:
          return esc ? all.replace(/^\\/, "") : b + "<em><strong>" + text + "</strong></em>";
        default:
          return all;
      }
    });

    str = str.replace(codeToHtmlRe, function(all, esc, text) {
      return esc ? all.replace(/^\\/, "") : "<code>" + text + "</code>";
    });

    return emojione.toImage(str);
  });
})();
