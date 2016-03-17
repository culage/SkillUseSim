// Generated by CoffeeScript 1.10.0
(function() {
  var $$, App, CookieAccess, CurrentSelectStorage, DataAccess, EventDispatcher, LastElementKeeper, Mons, MonsSwapper, MonsView, Team, TurnCounter, TurnView, ValueStorage, ValueStorageListView, mixin,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  mixin = function(o1, o2) {
    var key, results;
    results = [];
    for (key in o2.prototype) {
      results.push(o1.prototype[key] = o2.prototype[key]);
    }
    return results;
  };

  $$ = function(s) {
    return document.querySelector(s);
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
      if (!this.__ed_listeners) {
        return;
      }
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
      this.init();
    }

    App.prototype.init = function() {
      this.initSaveLoad();
      this.initMonsSwap();
      this.initSkillUse();
      this.initTurnCnt();
      return this.initTextSelect();
    };

    App.prototype.initSaveLoad = function() {
      var cookieAccess, i, id, ids, j, k, len, ref, ref1;
      cookieAccess = new CookieAccess();
      ids = ["#txtSaveName"];
      for (i = j = 0, ref = this.TEAM_MAX; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        ref1 = ["#txtSt" + i, "#txtHe" + i, "#txtSp" + i];
        for (k = 0, len = ref1.length; k < len; k++) {
          id = ref1[k];
          ids.push(id);
        }
      }
      this.vs = new ValueStorage(ids, cookieAccess);
      this.vs.addViewer(new ValueStorageListView("#lstSaveList"));
      $$("#btnSave").addEventListener("click", (function(_this) {
        return function() {
          _this.vs.save($$("#txtSaveName").value);
          return alert("保存しました。");
        };
      })(this));
      $$("#btnLoad").addEventListener("click", (function(_this) {
        return function() {
          _this.vs.load($$("#lstSaveList").selectedIndex);
          return $("#btnInit").click();
        };
      })(this));
      $$("#btnDel").addEventListener("click", (function(_this) {
        return function() {
          if (confirm("削除します。よろしいですか？") === true) {
            return _this.vs["delete"]($$("#lstSaveList").selectedIndex);
          }
        };
      })(this));
      this.css = new CurrentSelectStorage("#lstSaveList", cookieAccess);
      this.css.load();
      this.vs.load($$("#lstSaveList").selectedIndex);
      return window.addEventListener("unload", (function(_this) {
        return function() {
          return _this.css.save(_this.vs.currentIdx);
        };
      })(this));
    };

    App.prototype.initMonsSwap = function() {
      var i, j, ref;
      this.lastElement = new LastElementKeeper();
      this.swapper = new MonsSwapper();
      this.swapper.addEventListener("onSwaped", (function(_this) {
        return function(e) {
          return _this.lastElement.set(e.swapToElement);
        };
      })(this));
      for (i = j = 0, ref = this.TEAM_MAX; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        this.swapper.addMonsElement(["#txtSt" + i, "#txtHe" + i, "#txtSp" + i]);
        this.lastElement.addElement(["#txtSt" + i, "#txtHe" + i, "#txtSp" + i]);
      }
      $$("#btnSwapL").addEventListener("click", (function(_this) {
        return function() {
          return _this.swapper.swapLeft(_this.lastElement.get());
        };
      })(this));
      return $$("#btnSwapR").addEventListener("click", (function(_this) {
        return function() {
          return _this.swapper.swapRight(_this.lastElement.get());
        };
      })(this));
    };

    App.prototype.initSkillUse = function() {
      this.initTeam();
      $$("#btnInit").addEventListener("click", (function(_this) {
        return function() {
          return _this.initTeam();
        };
      })(this));
      return $$("#btnNext").addEventListener("click", (function(_this) {
        return function() {
          return _this.next();
        };
      })(this));
    };

    App.prototype.initTeam = function() {
      var haste, i, j, max, mons, preTurn, ref;
      this.team = new Team();
      for (i = j = 0, ref = this.TEAM_MAX; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        max = $$("#txtSt" + i).value;
        haste = $$("#txtHe" + i).value;
        preTurn = $$("#txtSp" + i).value;
        mons = new Mons(max, haste, preTurn);
        mons.addViewer(new MonsView("#btnMons" + i));
        $$("#btnMons" + i).onclick = this.createClickEventListener(mons);
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

    App.prototype.initTurnCnt = function() {
      this.turnCnt = new TurnCounter();
      this.turnCnt.addViewer(new TurnView("#txtNowTurn"));
      $$("#btnInit").addEventListener("click", (function(_this) {
        return function() {
          return _this.turnCnt.init();
        };
      })(this));
      return $$("#btnNext").addEventListener("click", (function(_this) {
        return function() {
          return _this.turnCnt.incTurn();
        };
      })(this));
    };

    App.prototype.initTextSelect = function() {
      var i, id, ids, j, k, l, len, len1, ref, ref1, results;
      ids = [];
      for (i = j = 0, ref = this.TEAM_MAX; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        ref1 = ["#txtSt" + i, "#txtHe" + i, "#txtSp" + i];
        for (k = 0, len = ref1.length; k < len; k++) {
          id = ref1[k];
          ids.push(id);
        }
      }
      results = [];
      for (l = 0, len1 = ids.length; l < len1; l++) {
        id = ids[l];
        results.push($$(id).addEventListener("click", function() {
          return this.select();
        }));
      }
      return results;
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

    Mons.prototype.addViewer = function(viewer) {
      this.addEventListener("onUpdateTurn", viewer);
      return this.onUpdateTurn();
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
      this.viewElement = $$(eleId);
    }

    MonsView.prototype.onUpdateTurn = function(e) {
      this.viewElement.value = e.turn;
      return this.viewElement.disabled = e.turn !== 0;
    };

    return MonsView;

  })();

  MonsSwapper = (function() {
    mixin(MonsSwapper, EventDispatcher);

    function MonsSwapper() {
      this.list = [];
    }

    MonsSwapper.prototype.addMonsElement = function(itemsId) {
      return this.list.push(itemsId.map((function(_this) {
        return function(id) {
          return $$(id);
        };
      })(this)));
    };

    MonsSwapper.prototype.swapLeft = function(activeElement) {
      return this.swapItem(activeElement, -1);
    };

    MonsSwapper.prototype.swapRight = function(activeElement) {
      return this.swapItem(activeElement, +1);
    };

    MonsSwapper.prototype.swapItem = function(activeElement, plus) {
      var itemsIndex, swapItemsIndex;
      itemsIndex = this.list.findIndex((function(_this) {
        return function(items) {
          return items.some(function(el) {
            return el === activeElement;
          });
        };
      })(this));
      if (itemsIndex === -1) {
        return;
      }
      swapItemsIndex = itemsIndex + plus;
      if (swapItemsIndex < 0 || this.list.length <= swapItemsIndex) {
        return;
      }
      this.swap(this.list[itemsIndex], this.list[swapItemsIndex]);
      return this.dispatchEvent({
        type: "onSwaped",
        swapToElement: this.list[swapItemsIndex][0]
      });
    };

    MonsSwapper.prototype.swap = function(items1, items2) {
      var el, i, j, len, results, swapValue;
      results = [];
      for (i = j = 0, len = items1.length; j < len; i = ++j) {
        el = items1[i];
        swapValue = items1[i].value;
        items1[i].value = items2[i].value;
        results.push(items2[i].value = swapValue);
      }
      return results;
    };

    return MonsSwapper;

  })();

  LastElementKeeper = (function() {
    function LastElementKeeper() {
      this.lastElement = null;
    }

    LastElementKeeper.prototype.addElement = function(itemsId) {
      var el, j, len, ref, results;
      ref = itemsId.map((function(_this) {
        return function(id) {
          return $$(id);
        };
      })(this));
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        el = ref[j];
        results.push(el.addEventListener("focus", (function(_this) {
          return function(e) {
            return _this.lastElement = e.target;
          };
        })(this)));
      }
      return results;
    };

    LastElementKeeper.prototype.set = function(el) {
      return this.lastElement = el;
    };

    LastElementKeeper.prototype.get = function() {
      return this.lastElement;
    };

    return LastElementKeeper;

  })();

  ValueStorage = (function() {
    mixin(ValueStorage, EventDispatcher);

    function ValueStorage(itemsId, dataAccess) {
      var error;
      this.LIST_KEY = "list";
      this.itemsEl = itemsId.map((function(_this) {
        return function(id) {
          return $$(id);
        };
      })(this));
      this.dataAccess = dataAccess;
      try {
        this.list = JSON.parse(this.dataAccess.load(this.LIST_KEY));
      } catch (error) {
        this.list = [];
      }
    }

    ValueStorage.prototype.save = function(name) {
      var datas, el, j, len, ref;
      if (name === "") {
        return;
      }
      this.currentIdx = this.list.indexOf(name);
      if (this.currentIdx === -1) {
        this.list.push(name);
        this.currentIdx = this.list.length - 1;
      }
      this.updateList();
      this.onSave(this.currentIdx);
      datas = {};
      ref = this.itemsEl;
      for (j = 0, len = ref.length; j < len; j++) {
        el = ref[j];
        datas[el.id] = el.value;
      }
      return this.dataAccess.save(this.getDataKey(this.list.indexOf(name)), JSON.stringify(datas));
    };

    ValueStorage.prototype.getDataKey = function(dataIdx) {
      return "item" + dataIdx;
    };

    ValueStorage.prototype.load = function(dataIdx) {
      var datas, id, value;
      if (dataIdx === -1) {
        return;
      }
      datas = this.dataAccess.load(this.getDataKey(dataIdx));
      datas = JSON.parse(datas);
      for (id in datas) {
        value = datas[id];
        $$("#" + id).value = value;
      }
      return this.currentIdx = dataIdx;
    };

    ValueStorage.prototype["delete"] = function(dataIdx) {
      if (dataIdx === -1) {
        return;
      }
      this.list = this.list.filter((function(_this) {
        return function(dummy, idx) {
          return idx !== dataIdx;
        };
      })(this));
      return this.updateList();
    };

    ValueStorage.prototype.updateList = function() {
      this.dataAccess.save(this.LIST_KEY, JSON.stringify(this.list));
      return this.dispatchEvent({
        type: "onUpdateList",
        list: this.list
      });
    };

    ValueStorage.prototype.onSave = function(saveIdx) {
      return this.dispatchEvent({
        type: "onSave",
        saveIdx: saveIdx
      });
    };

    ValueStorage.prototype.addViewer = function(viewer) {
      this.addEventListener("onUpdateList", viewer);
      this.addEventListener("onSave", viewer);
      return this.updateList();
    };

    return ValueStorage;

  })();

  ValueStorageListView = (function() {
    function ValueStorageListView(id) {
      this.el = $$(id);
    }

    ValueStorageListView.prototype.onUpdateList = function(e) {
      var item, j, k, len, option, ref, ref1, results;
      for (j = 0, ref = this.el.length - 1; 0 <= ref ? j <= ref : j >= ref; 0 <= ref ? j++ : j--) {
        this.el.remove(0);
      }
      ref1 = e.list;
      results = [];
      for (k = 0, len = ref1.length; k < len; k++) {
        item = ref1[k];
        option = document.createElement("option");
        option.text = item;
        results.push(this.el.add(option));
      }
      return results;
    };

    ValueStorageListView.prototype.onSave = function(e) {
      return this.el.selectedIndex = e.saveIdx;
    };

    return ValueStorageListView;

  })();

  DataAccess = (function() {
    function DataAccess() {}

    DataAccess.prototype.save = function(key, val) {};

    DataAccess.prototype.load = function(key) {};

    DataAccess.prototype["delete"] = function(key) {};

    return DataAccess;

  })();

  CookieAccess = (function(superClass) {
    extend(CookieAccess, superClass);

    function CookieAccess() {
      this.DAY1000 = 60 * 60 * 24 * 1000;
    }

    CookieAccess.prototype.save = function(key, val) {
      return document.cookie = key + "=" + (encodeURIComponent(val)) + "; max-age=" + this.DAY1000;
    };

    CookieAccess.prototype.load = function(loadKey) {
      var datas, j, key, keyAndValue, keyAndValues, len, ref, value;
      datas = {};
      keyAndValues = document.cookie.split("; ");
      for (j = 0, len = keyAndValues.length; j < len; j++) {
        keyAndValue = keyAndValues[j];
        ref = keyAndValue.split("="), key = ref[0], value = ref[1];
        datas[key] = value;
      }
      return decodeURIComponent(datas[loadKey]);
    };

    CookieAccess.prototype["delete"] = function(key) {
      return document.cookie = key + "=";
    };

    return CookieAccess;

  })(DataAccess);

  CurrentSelectStorage = (function() {
    function CurrentSelectStorage(selectId, dataAccess) {
      this.DATA_KEY = "current_data_index";
      this.selectEl = $$(selectId);
      this.dataAccess = dataAccess;
    }

    CurrentSelectStorage.prototype.save = function(saveIdx) {
      return this.dataAccess.save(this.DATA_KEY, saveIdx);
    };

    CurrentSelectStorage.prototype.load = function() {
      return this.selectEl.selectedIndex = this.dataAccess.load(this.DATA_KEY);
    };

    return CurrentSelectStorage;

  })();

  TurnCounter = (function() {
    mixin(TurnCounter, EventDispatcher);

    function TurnCounter() {
      this.init();
    }

    TurnCounter.prototype.init = function() {
      this.turn = 1;
      return this.onUpdateTurn();
    };

    TurnCounter.prototype.incTurn = function() {
      this.turn += 1;
      return this.onUpdateTurn();
    };

    TurnCounter.prototype.addViewer = function(viewer) {
      this.addEventListener("onUpdateTurn", viewer);
      return this.onUpdateTurn();
    };

    TurnCounter.prototype.onUpdateTurn = function() {
      return this.dispatchEvent({
        type: "onUpdateTurn",
        turn: this.turn
      });
    };

    return TurnCounter;

  })();

  TurnView = (function() {
    function TurnView(id) {
      this.el = $$(id);
    }

    TurnView.prototype.onUpdateTurn = function(e) {
      return this.el.innerHTML = e.turn;
    };

    return TurnView;

  })();

  window.addEventListener("load", function() {
    var app;
    return app = new App();
  });

}).call(this);
