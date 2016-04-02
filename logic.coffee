mixin = (o1, o2) -> o1.prototype[key] = o2.prototype[key] for key of o2.prototype

$$ = (s) -> document.querySelector(s)

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
		@initTurnCnt()
		@initTextSelect()

	initSaveLoad: ->
		cookieAccess = new CookieAccess()
	
		ids = ["#txtSaveName"]
		for i in [0..@TEAM_MAX]
			ids.push id for id in ["#txtSt#{i}", "#txtHe#{i}", "#txtSp#{i}", "#txtS2St#{i}", "#txtS2He#{i}"]
		@vs = new ValueStorage(ids, cookieAccess)
		@vs.addViewer new ValueStorageListView("#lstSaveList")

		$$("#btnSave").addEventListener "click", =>
			@vs.save    $$("#txtSaveName").value
			alert "保存しました。"
		$$("#btnLoad").addEventListener "click", =>
			@vs.load    $$("#lstSaveList").selectedIndex
			$("#btnInit").click()
		$$("#btnDel" ).addEventListener "click", =>
			if confirm("削除します。よろしいですか？") == true
				@vs.delete  $$("#lstSaveList").selectedIndex
		
		@css = new CurrentSelectStorage("#lstSaveList", cookieAccess)
		@css.load()
		@vs.load $$("#lstSaveList").selectedIndex
		
		window.addEventListener "unload", => @css.save @vs.currentIdx

	initMonsSwap: ->
		@lastElement = new LastElementKeeper()

		@swapper = new MonsSwapper()
		@swapper.addEventListener "onSwaped", (e) => @lastElement.set(e.swapToElement)

		for i in [0..@TEAM_MAX]
			@swapper.addMonsElement ["#txtSt#{i}", "#txtHe#{i}", "#txtSp#{i}", "#txtS2St#{i}", "#txtS2He#{i}"]
			@lastElement.addElement ["#txtSt#{i}", "#txtHe#{i}", "#txtSp#{i}", "#txtS2St#{i}", "#txtS2He#{i}"]

		$$("#btnSwapL").addEventListener "click", => @swapper.swapLeft (@lastElement.get())
		$$("#btnSwapR").addEventListener "click", => @swapper.swapRight(@lastElement.get())

	initSkillUse: ->
		@initTeam()

		$$("#btnInit").addEventListener "click", => @initTeam()
		$$("#btnNext").addEventListener "click", => @next()

	initTeam: ->
		@team = new Team()

		for i in [0..@TEAM_MAX]
			max     = Number($$("#txtSt#{i}").value);
			haste   = Number($$("#txtHe#{i}").value);
			preTurn = Number($$("#txtSp#{i}").value);
			s2max   = Number($$("#txtS2St#{i}").value);
			s2haste = Number($$("#txtS2He#{i}").value);
			mons = new Mons(max, haste, preTurn, s2max, s2haste)
			mons.addViewer new MonsView("#btnMons#{i}")
			
			# このイベントは上書きしたいので、onclickに代入する
			$$("#btnMons#{i}").onclick = @createClickEventListener(mons)
			@team.add mons
		
		@team.preCharge()

	createClickEventListener: (mons) ->
		return -> mons.invoke()

	next: ->
		@team.decTurn 1

	initTurnCnt: ->
		@turnCnt = new TurnCounter()
		@turnCnt.addViewer new TurnView("#txtNowTurn")
		
		$$("#btnInit").addEventListener "click", => @turnCnt.init()
		$$("#btnNext").addEventListener "click", => @turnCnt.incTurn()

	initTextSelect: ->
		ids = []
		for i in [0..@TEAM_MAX]
			ids.push id for id in ["#txtSt#{i}", "#txtHe#{i}", "#txtSp#{i}", "#txtS2St#{i}","#txtS2He#{i}"]
		for id in ids
			$$(id).addEventListener "click", -> this.select()

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
	constructor: (@max, @haste, @preTurn, @s2max, @s2haste) ->
		@team = null
		@initTurn()
	initTurn: ->
		@turn = @max
		if @hasS2()
			@s2turn = @max + @s2max
		else
			@s2turn = 0
	hasS2: ->
		@s2max > 0
	setTeam: (team) ->
		@team = team
	decTurn: (dec) ->
		@turn -= dec
		if @turn < 0
			@turn = 0
		@s2turn -= dec
		if @s2turn < 0
			@s2turn = 0
		@onUpdateTurn()
	preCharge: ->
		@team.decTurn @preTurn
	invoke: ->
		if @hasS2() && @s2turn == 0
			@initTurn()
			@onUpdateTurn()
			if @s2haste > 0
				@team.decTurn @s2haste, @
			return
		if @turn == 0
			@initTurn()
			@onUpdateTurn()
			if @haste > 0
				@team.decTurn @haste, @
			return
	addViewer: (viewer) ->
		@addEventListener "onUpdateTurn", viewer
		@onUpdateTurn()
	onUpdateTurn: ->
		@dispatchEvent {type: "onUpdateTurn", turn: @turn, s2turn: @s2turn, hasS2: @hasS2()}

class MonsView
	constructor: (eleId) ->
		@viewElement = $$(eleId);
	onUpdateTurn: (e) ->
		s1turnView = e.turn
		s2turnView = if e.hasS2 == true then e.s2turn else "-"
		if  e.hasS2 == true and e.turn == 0
			s1charging = "class='skill-non-charging'"
			s2charging = "class='skill-charging'"
		else
			s1charging = "class='skill-charging'"
			s2charging = "class='skill-non-charging'"
		@viewElement.innerHTML = "<span class='skill-num'>S1:</span><span #{s1charging}>#{s1turnView}</span><br>
		                          <span class='skill-num'>S2:</span><span #{s2charging}>#{s2turnView}</span>"
		
		@viewElement.disabled = (e.turn != 0);
		if e.s2turn == 0 and e.hasS2 == true and 
			$(@viewElement).addClass("s2-charge");
		else
			$(@viewElement).removeClass("s2-charge");

class MonsSwapper
	mixin @, EventDispatcher
	constructor: ->
		@list = []
	addMonsElement: (itemsId) ->
		@list.push itemsId.map((id) => $$(id))
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
		@dispatchEvent { type: "onSwaped", swapToElement: @list[swapItemsIndex][0] }
	swap: (items1, items2) ->
		for el, i in items1
			swapValue       = items1[i].value
			items1[i].value = items2[i].value
			items2[i].value = swapValue

class LastElementKeeper
	constructor: ->
		@lastElement = null
	addElement: (itemsId) ->
		for el in itemsId.map((id) => $$(id))
			el.addEventListener "focus", (e) => @lastElement = e.target
	set: (el) ->
		@lastElement = el
	get: ->
		return @lastElement


class ValueStorage
	mixin @, EventDispatcher
	constructor: (itemsId, dataAccess) ->
		@LIST_KEY = "list"
		@itemsEl = itemsId.map((id) => $$(id))
		@dataAccess = dataAccess
		try
			@list = JSON.parse(@dataAccess.load(@LIST_KEY))
		catch
			@list = []
	save: (name) ->
		if name == "" then return
		@currentIdx = @list.indexOf(name)
		if @currentIdx == -1
			@list.push name
			@currentIdx = @list.length - 1
		@updateList()
		@onSave @currentIdx
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
			$$("#" + id).value = value if $$("#" + id)
		@currentIdx = dataIdx
	delete: (dataIdx) ->
		if dataIdx == -1 then return
		@list = @list.filter((dummy,idx) => idx != dataIdx)
		@updateList()
	updateList: ->
		@dataAccess.save @LIST_KEY, JSON.stringify(@list)
		@dispatchEvent {type: "onUpdateList", list: @list }
	onSave: (saveIdx) ->
		@dispatchEvent {type: "onSave", saveIdx: saveIdx }
	addViewer: (viewer) ->
		@addEventListener "onUpdateList", viewer
		@addEventListener "onSave"      , viewer
		@updateList()

class ValueStorageListView
	constructor: (id) ->
		@el = $$(id)
	onUpdateList: (e) ->
		@el.remove(0) for [0..(@el.length - 1)]
		for item in e.list
			option = document.createElement("option")
			option.text = item
			@el.add option
	onSave: (e) ->
		@el.selectedIndex = e.saveIdx

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

class CurrentSelectStorage
	constructor: (selectId, dataAccess) ->
		@DATA_KEY = "current_data_index"
		@selectEl = $$(selectId)
		@dataAccess = dataAccess
	save: (saveIdx)->
		@dataAccess.save @DATA_KEY, saveIdx
	load: ->
		@selectEl.selectedIndex = @dataAccess.load(@DATA_KEY)



class TurnCounter
	mixin @, EventDispatcher
	constructor: ->
		@init()
	init: ->
		@turn = 1
		@onUpdateTurn()
	incTurn: ->
		@turn += 1
		@onUpdateTurn()
	addViewer: (viewer) ->
		@addEventListener "onUpdateTurn", viewer
		@onUpdateTurn()
	onUpdateTurn: ->
		@dispatchEvent { type: "onUpdateTurn", turn: @turn }

class TurnView
	constructor: (id) ->
		@el = $$(id)
	onUpdateTurn: (e) ->
		@el.innerHTML = e.turn

window.addEventListener "load", ->
	app = new App()



