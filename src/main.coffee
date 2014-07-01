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
      @emit('pair', { id: @id }, 'pair')
      if qs.debug?
        @emit('debug', true, 'debug')
      @_resolveEventQueue()
      callback?()

    @_ws.onmessage = (e) =>
      try
        data = JSON.parse(e.data)
      catch
        console.error "Event data can't be parsed", e

      if data.type in ['panel-event', 'global-event']
        @_emit(data.name, data.params)
      if data.type is 'debug' and qs.debug?
        @_handleDebugEvent(data.params)

  emit: (name, params, type = 'server-event') ->
    msg = JSON.stringify
      id: @id
      name: name
      type: type
      params: params

    if @connected
      @_ws.send msg
    else
      @_eventQueue.push msg

  _handleDebugEvent: (e) ->
    if e.extension in ['less', 'css']
      return Array.prototype.forEach.call document.querySelectorAll("link[href*=\"#{e.filepath}\"]"), (s) ->
        s.href = s.href.replace(/\?.*/, '') + '?debug' + Math.random().toString().substr(2)
    if e.extension in ['js', 'coffee']
      return document.location.reload()

  _resolveEventQueue: ->
    @_ws.send e for e in @_eventQueue
    @_eventQueue = []

window.Bridge = Bridge
