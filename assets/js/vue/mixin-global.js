(function() {
  // localStorage items are maintained in root Vue object, in main.js
  // TODO: Should come up with better variable names than "main" and "sidebar"
  Convos.settings.main = localStorage.getItem("main") || "";
  Convos.settings.sidebar = localStorage.getItem("sidebar") || "";
  Convos.settings.dialogsVisible = false;
  Convos.settings.notifications = localStorage.getItem("notifications") || Notification.permission;
  Convos.settings.sortDialogsBy = localStorage.getItem("sortDialogsBy") || "";

  if (Convos.settings.sidebar) $('body').addClass('has-sidebar');

  var resizeTid;
  var measureWindow = function() {
    resizeTid = null;
    Convos.settings.screenHeight = window.innerHeight;
    Convos.settings.screenWidth = window.innerWidth;
  };

  measureWindow();
  window.addEventListener("resize", function() {
    if (!resizeTid) resizeTid = setTimeout(measureWindow, 100);
  });

  Vue.mixin({
    data: function() {
      return {settings: Convos.settings};
    },
    methods: {
      activeClass: function(href) {
        return {active: Convos.settings.main == href || Convos.settings.sidebar == href};
      },
      enableNotifications: function(enable) {
        if (!enable) return this.settings.notifications = "denied";
        Notification.requestPermission(function(s) { if (s) this.settings.notifications = s; }.bind(this));
      },
      insertIntoInput: function(e) {
        var dialog = this.user.getActiveDialog();
        if (dialog) dialog.emit("insertIntoInput", e.currentTarget.href.replace(/.*?#/, ""));
      },
      send: function(command) {
        this.dialog.connection().send(command, this.dialog);
      }
    }
  });
})();
