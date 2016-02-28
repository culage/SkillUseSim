var App, EventDispatcher, Mons, MonsView, Team, app, mixin;

mixin = function(o1, o2) {
  var key, results;
  results = [];
  for (key in o2.prototype) {
    results.push(o1.prototype[key] = o2.prototype[key]);
  }
  return results;
};

EventDispatcher = (function() {
  function EventDispatcher() {}

  EventDispatcher.prototype.addEventListener = function(type, obj) {
    if (!this.__ed_listeners) {
      this.__ed_listeners = {};
    }
    if (!this.__ed_listeners[type]) {
      this.__ed_listeners[type] = [];
    }
    return this.__ed_listeners[type].push(obj);
  };

  EventDispatcher.prototype.dispatchEvent = function(e) {
    var j, len, listener, ref, results;
    if (!this.__ed_listeners[e.type]) {
      return;
    }
    if (!e.target) {
      e.target = this;
    }
    ref = this.__ed_listeners[e.type];
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      listener = ref[j];
      if (typeof listener === "object") {
        results.push(listener[e.type].call(listener, e));
      } else {
        results.push(listener(e));
      }
    }
    return results;
  };

  return EventDispatcher;

})();

App = (function() {
  function App() {
    this.TEAM_MAX = 5;
    var self = this;
    document.getElementById("btnInit").onclick = function (){ self.init(); };
    document.getElementById("btnNext").onclick = function (){ self.next(); };
    self.init();
  }

  App.prototype.init = function() {
    var haste, i, j, max, mons, preTurn, ref;
    this.team = new Team();
    for (var i = 0; i<=this.TEAM_MAX; i++) {
      max = document.getElementById("txtSt" + i).value;
      haste = document.getElementById("txtHe" + i).value;
      preTurn = document.getElementById("txtSp" + i).value;
      mons = new Mons(max, haste, preTurn);
      mons.addEventListener("onUpdateTurn", new MonsView("btnMons" + i));
      document.getElementById("btnMons" + i).onclick = this.createClickEventListener(mons);
      this.team.add(mons);
    }

    return this.team.preCharge();
  };

  App.prototype.createClickEventListener = function(mons) {
    return function() {
      return mons.invoke();
    };
  };

  App.prototype.next = function() {
    return this.team.decTurn(1);
  };

  return App;

})();

Team = (function() {
  function Team() {
    this.list = [];
  }

  Team.prototype.add = function(mons) {
    this.list.push(mons);
    return mons.setTeam(this);
  };

  Team.prototype.preCharge = function() {
    var j, len, mons, ref, results;
    ref = this.list;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      mons = ref[j];
      results.push(mons.preCharge());
    }
    return results;
  };

  Team.prototype.decTurn = function(dec, expect) {
    var j, len, mons, ref, results;
    ref = this.list;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      mons = ref[j];
      if (mons !== expect) {
        results.push(mons.decTurn(dec));
      }
    }
    return results;
  };

  return Team;

})();

Mons = (function() {
  mixin(Mons, EventDispatcher);

  function Mons(max1, haste1, preTurn1) {
    this.max = max1;
    this.haste = haste1;
    this.preTurn = preTurn1;
    this.team = null;
    this.turn = this.max;
  }

  Mons.prototype.setTeam = function(team) {
    return this.team = team;
  };

  Mons.prototype.decTurn = function(dec) {
    this.turn -= dec;
    if (this.turn < 0) {
      this.turn = 0;
    }
    return this.onUpdateTurn();
  };

  Mons.prototype.preCharge = function() {
    return this.team.decTurn(this.preTurn);
  };

  Mons.prototype.invoke = function() {
    if (this.turn > 0) {
      return;
    }
    this.turn = this.max;
    this.onUpdateTurn();
    if (this.haste > 0) {
      return this.team.decTurn(this.haste, this);
    }
  };

  Mons.prototype.onUpdateTurn = function() {
    return this.dispatchEvent({
      type: "onUpdateTurn",
      turn: this.turn
    });
  };

  return Mons;

})();

MonsView = (function() {
  function MonsView(eleId) {
    this.viewElement = document.getElementById(eleId);
  }

  MonsView.prototype.onUpdateTurn = function(e) {
    this.viewElement.value = e.turn;
    this.viewElement.disabled = (e.turn != 0);
  };

  return MonsView;

})();

window.onload = function () {
  app = new App();
}
