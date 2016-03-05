mixin = (o1, o2) -> o1.prototype[key] = o2.prototype[key] for key of o2.prototype

class EventDispatcher
	addEventListener: (type, obj) ->
		@__ed_listeners       = {} if not @__ed_listeners
		@__ed_listeners[type] = [] if not @__ed_listeners[type]
		@__ed_listeners[type].push obj;
	dispatchEvent: (e) ->
		if not @__ed_listeners
			return
		if not @__ed_listeners[e.type]
			return
		e.target = @ if not e.target
		for listener in @__ed_listeners[e.type]
			if typeof(listener) == "object"
				listener[e.type].call listener, e
			else
				listener e

class App
	constructor: ->
		@TEAM_MAX = 5
		@init()

	init: ->
		@initSaveLoad()
		@initMonsSwap()
		@initSkillUse()

	initSaveLoad: ->
		ids = []
		for i in [0..@TEAM_MAX]
			ids.push id for id in ["txtSt#{i}", "txtHe#{i}", "txtSp#{i}"]
		@vs = new ValueStorage(ids, new CookieAccess())
		@vs.addViewer new ValueStorageListView("lstSaveList")

		document.getElementById("btnSave").onclick = => @vs.save    document.getElementById("txtSaveName").value
		document.getElementById("btnLoad").onclick = => @vs.load    document.getElementById("lstSaveList").selectedIndex
		document.getElementById("btnDel" ).onclick = => @vs.delete  document.getElementById("lstSaveList").selectedIndex

	initMonsSwap: ->
		@swapper = new MonsSwapper()
		@lastElement = new LastElementKeeper()

		for i in [0..@TEAM_MAX]
			@swapper.addMonsElement ["txtSt#{i}", "txtHe#{i}", "txtSp#{i}"]
			@lastElement.addElement ["txtSt#{i}", "txtHe#{i}", "txtSp#{i}"]

		document.getElementById("btnSwapL").onclick = => @swapper.swapLeft (@lastElement.get())
		document.getElementById("btnSwapR").onclick = => @swapper.swapRight(@lastElement.get())

	initSkillUse: ->
		@team = new Team()

		for i in [0..@TEAM_MAX]
			max     = document.getElementById("txtSt#{i}").value;
			haste   = document.getElementById("txtHe#{i}").value;
			preTurn = document.getElementById("txtSp#{i}").value;
			mons = new Mons(max, haste, preTurn)
			mons.addViewer new MonsView("btnMons#{i}")
			
			document.getElementById("btnMons#{i}").onclick = @createClickEventListener(mons)
			@team.add mons
		
		@team.preCharge()

		document.getElementById("btnInit").onclick = => @init()
		document.getElementById("btnNext").onclick = => @next()

	createClickEventListener: (mons) ->
		return -> mons.invoke()

	next: ->
		@team.decTurn 1

class Team
	constructor: ->
		@list = []
	add: (mons) ->
		@list.push mons
		mons.setTeam @
	preCharge: ->
		mons.preCharge() for mons in @list
	decTurn: (dec, expect) ->
		mons.decTurn(dec) for mons in @list when mons != expect

class Mons
	mixin @, EventDispatcher
	constructor: (@max, @haste, @preTurn) ->
		@team = null
		@turn = @max
	setTeam: (team) ->
		@team = team
	decTurn: (dec) ->
		@turn -= dec
		if @turn < 0
			@turn = 0
		@onUpdateTurn()
	preCharge: ->
		@team.decTurn @preTurn
	invoke: ->
		if @turn > 0
			return
		@turn = @max
		@onUpdateTurn()
		if @haste > 0
			@team.decTurn @haste, @
	addViewer: (viewer) ->
		@addEventListener "onUpdateTurn", viewer
		@onUpdateTurn()
	onUpdateTurn: ->
		@dispatchEvent {type: "onUpdateTurn", turn: @turn}

class MonsView
	constructor: (eleId) ->
		@viewElement = document.getElementById(eleId);
	onUpdateTurn: (e) ->
		@viewElement.value = e.turn
		@viewElement.disabled = (e.turn != 0);


class MonsSwapper
	constructor: ->
		@list = []
	addMonsElement: (itemsId) ->
		@list.push itemsId.map((id) => document.getElementById(id))
	swapLeft: (activeElement) ->
		@swapItem activeElement, -1
	swapRight: (activeElement) ->
		@swapItem activeElement, +1
	swapItem: (activeElement, plus) ->
		itemsIndex = @list.findIndex( (items) => items.some((el) => el == activeElement) )
		if itemsIndex == -1 then return
		swapItemsIndex = itemsIndex + plus
		if swapItemsIndex < 0 or @list.length <= swapItemsIndex
			return
		@swap @list[itemsIndex], @list[swapItemsIndex]
		@list[swapItemsIndex][0].focus()
	swap: (items1, items2) ->
		for el, i in items1
			swapValue       = items1[i].value
			items1[i].value = items2[i].value
			items2[i].value = swapValue

class LastElementKeeper
	constructor: ->
		@lastElement = null
	addElement: (itemsId) ->
		for el in itemsId.map((id) => document.getElementById(id))
			el.addEventListener "focus", (e) => @lastElement = e.target
	get: ->
		return @lastElement


class ValueStorage
	mixin @, EventDispatcher
	constructor: (itemsId, dataAccess) ->
		@LIST_KEY = "list"
		@itemsEl = itemsId.map((id) => document.getElementById(id))
		@dataAccess = dataAccess
		try
			@list = JSON.parse(@dataAccess.load(@LIST_KEY))
		catch
			@list = []
	save: (name) ->
		if name == "" then return
		@list.push name if @list.indexOf(name) == -1
		@updateList()
		datas = {}
		datas[el.id] = el.value for el in @itemsEl
		@dataAccess.save @getDataKey(@list.indexOf(name)), JSON.stringify(datas)
	getDataKey: (dataIdx) ->
		return "item#{dataIdx}"
	load: (dataIdx) ->
		if dataIdx == -1 then return
		datas = @dataAccess.load(@getDataKey(dataIdx))
		datas = JSON.parse(datas)
		for id, value of datas
			document.getElementById(id).value = value
	delete: (dataIdx) ->
		if dataIdx == -1 then return
		@list = @list.filter((dummy,idx) => idx != dataIdx)
		@updateList()
	updateList: ->
		@dataAccess.save @LIST_KEY, JSON.stringify(@list)
		@dispatchEvent {type: "onUpdateList", list: @list }
	addViewer: (viewer) ->
		@addEventListener "onUpdateList", viewer
		@updateList()

class ValueStorageListView
	constructor: (id) ->
		@el = document.getElementById(id)
	onUpdateList: (e) ->
		@el.remove(0) for [0..(@el.length - 1)]
		for item in e.list
			option = document.createElement("option")
			option.text = item
			@el.add option
	onAddItem: (e) ->
		#星アクティブにする

class DataAccess
	save  : (key, val) ->
	load  : (key) ->
	delete: (key) ->

class CookieAccess extends DataAccess
	constructor: ->
		@DAY1000 = 60 * 60 * 24 * 1000
	save: (key, val) ->
		document.cookie = "#{key}=#{encodeURIComponent(val)}; max-age=#{@DAY1000}"
	load: (loadKey) ->
		datas = {}
		keyAndValues = document.cookie.split("; ")
		for keyAndValue in keyAndValues
			[ key, value ] = keyAndValue.split("=")
			datas[key] = value
		return decodeURIComponent(datas[loadKey])
	delete: (key) ->
		document.cookie = "#{key}="


window.onload = ->
	app = new App()





