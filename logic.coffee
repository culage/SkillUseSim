mixin = (o1, o2) -> o1.prototype[key] = o2.prototype[key] for key of o2.prototype

class EventDispatcher
	addEventListener: (type, obj) ->
		@__ed_listeners       = {} if not @__ed_listeners
		@__ed_listeners[type] = [] if not @__ed_listeners[type]
		@__ed_listeners[type].push obj;
	dispatchEvent: (e) ->
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
		document.getElementById("btnInit").onclick = => @init()
		document.getElementById("btnNext").onclick = => @next()
		@init()

	init: ->
		@team = new Team()

		for i in [0..@TEAM_MAX]
			max     = document.getElementById("txtSt#{i}").value;
			haste   = document.getElementById("txtHe#{i}").value;
			preTurn = document.getElementById("txtSp#{i}").value;
			mons = new Mons(max, haste, preTurn)
			mons.addEventListener "onUpdateTurn", new MonsView("btnMons#{i}")
			
			document.getElementById("btnMons#{i}").onclick = @createClickEventListener(mons)
			@team.add mons
		
		@team.preCharge()

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
	onUpdateTurn: ->
		@dispatchEvent {type: "onUpdateTurn", turn: @turn}

class MonsView
	constructor: (eleId) ->
		@viewElement = document.getElementById(eleId);
	onUpdateTurn: (e) ->
		@viewElement.value = e.turn
		@viewElement.disabled = (e.turn != 0);

window.onload = ->
	app = new App()

