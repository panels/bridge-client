{EventEmitter} = require 'events'

EventEmitter.prototype._emit = EventEmitter.prototype.emit

class Bridge extends EventEmitter
  constructor: (callback) ->
    @id = window.location.pathname.replace(/\//g, '')
    @ws = new WebSocket("ws://#{window.location.host}")

    @ws.onopen = (event) =>
      @_send('pair', {id: @id})
      callback?()

    @ws.onmessage = (e) =>
      data = JSON.parse(e.data)
      if data.type == 'callback'
        @_emit(data.func, data.params)

  emit: (func, params) ->
    @_send('callFunc', id: @id, func: func, params: params)

  _send: (type, data) ->
    msg =
      type: type
      data: data
    @ws.send(JSON.stringify(msg))

window.Bridge = Bridge
