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
				listener[eventName].call listener, e
			else
				listener e

class App
	constructor: ->
		@TEAM_MAX = 5
		document.getElementById("●").onclick = @init
		document.getElementById("●").onclick = @next

	init: ->
		@team = new Team()

		for i in [0..@TEAM_MAX]
			max       = document.getElementById("●").value;
			haste     = document.getElementById("●").value;
			preCharge = document.getElementById("●").value;
			mons = new Mons(max, haste, preCharge)
			mons.addEventListener "onUpdateTurn", new MonsView("●")
			
			document.getElementById("●").onclick = @createClickEventListener(mons)
			@team.add mons
		
		@team.preCharge()

	createClickEventListener: (mons) ->
		return (mons) -> mons.invoke()

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
	decTurn: (dec) ->
		mons.decTurn(dec) for mons in @list

class Mons
	mixin @, EventDispatcher
	constructor: (@max, @haste, @preCharge) ->
		@team = null
		@turn = @max
		@onUpdateTurn()
	setTeam: (team) ->
		@team = team
	decTurn: (dec) ->
		@turn -= dec
		if @turn < 0
			@turn = 0
		@onUpdateTurn()
	preCharge: ->
		@team.decTurn @preCharge
	invoke: ->
		if @turn > 0
			return
		@turn = @max
		@onUpdateTurn()
		if @haste > 0
			team.decTurn @haste
	onUpdateTurn: ->
		@dispatchEvent {type: "onUpdateTurn", turn: @turn}

class MonsView
	constructor: (eleId) ->
		@viewElement = getElementById(eleId);
	onUpdateTurn: (e) ->
		@viewElement.value = e.turn


app = new App()

