{EventEmitter} = require 'events'
querystring = require 'querystring'

EventEmitter.prototype._emit = EventEmitter.prototype.emit

class Bridge extends EventEmitter
  constructor: (callback) ->
    qs = querystring.parse(window.location.search.replace(/^\?/, ''))
    @_id = if qs.id? then qs.id else 'default'

    server = "ws://#{window.location.host}"

    @debugMode = false
    if qs.debug?
      @_startDebugMode()

    @platform = qs.platform || 'unknown'
    document.documentElement.classList.add "platform-#{@platform}"

    @_ws = new WebSocket server
    @connected = false

    @_eventQueue = []

    @_ws.onopen = (event) =>
      @_log 'Socket connected'

      @connected = true
      @emit 'pair', { id: @id }, 'pair'

      if @debugMode
        @emit 'debug', true, 'debug'

      @_resolveEventQueue()
      callback?()

    @_log 'Initialized', { backend: server, platform: @platform }

    @_ws.onmessage = (e) =>
      try
        data = JSON.parse(e.data)
      catch
        console.error "Event data can't be parsed", e

      @_log 'Message received', data

      if data.type in ['panel-event', 'global-event']
        @_emit data.name, data.params
      if data.type is 'debug' and @debugMode
        @_handleDebugEvent data.params

  emit: (name, params, type = 'server-event') ->
    obj =
      id: @_id
      name: name
      type: type
      params: params

    msg = JSON.stringify obj

    @_log 'Emitting', obj

    if @connected
      @_ws.send msg
    else
      @_eventQueue.push msg

  _log: ->
    if @debugMode
      args = [].slice.call arguments
      args.unshift '[panel-bridge-client]'
      console.info.apply console, args

  _startDebugMode: ->
    @debugMode = true
    @_log 'Debug mode active'

  _handleDebugEvent: (e) ->
    @_log 'File changed event', e

    if e.extension in ['less', 'css']
      @_log 'Reloading styles'
      return Array.prototype.forEach.call document.querySelectorAll("link[href*=\"#{e.filepath}\"]"), (s) ->
        s.href = s.href.replace(/\?.*/, '') + '?debug' + Math.random().toString().substr(2)
    if e.extension in ['js', 'coffee', 'html']
      @_log 'Reloading document'
      return document.location.reload()

  _resolveEventQueue: ->
    @_ws.send e for e in @_eventQueue
    @_eventQueue = []

window.Bridge = Bridge
