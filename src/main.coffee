{EventEmitter} = require 'events'
querystring = require 'querystring'

EventEmitter.prototype._emit = EventEmitter.prototype.emit

class Bridge extends EventEmitter
  constructor: (callback) ->
    qs = querystring.parse(window.location.search.replace(/^\?/, ''))
    @_id = if qs.id? then qs.id else 'default'

    @platform = qs.platform || 'unknown'
    document.documentElement.classList.add("platform-#{@platform}")

    @_ws = new WebSocket("ws://#{window.location.host}")
    @connected = false

    @_eventQueue = []

    @_ws.onopen = (event) =>
      @connected = true
      @_send('pair', { id: @id })
      @_resolveEventQueue()
      callback?()

    @_ws.onmessage = (e) =>
      try
        data = JSON.parse(e.data)
      catch
        console.error "Event data can't be parsed", e

      if data.type in ['panel-event', 'global-event']
        @_emit(data.name, data.params)

  emit: (name, params, type = 'server-event') ->
    @_send type,
      id: @id
      name: name
      params: params

  _resolveEventQueue: ->
    @_ws.send e for e in @_eventQueue
    @_eventQueue = []

  _send: (type, params) ->
    msg = JSON.stringify
      type: type
      params: params or null

    if @connected
      @_ws.send msg
    else
      @_eventQueue.push msg


window.Bridge = Bridge
