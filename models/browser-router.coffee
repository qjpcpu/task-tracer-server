debug = require 'debug'
path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs'

log = debug 'ttServer:browser-router'

class BrowserRouter
  forSocket: (socket,browserConfig) ->
    unless browserConfig.task?.name? and browserConfig.from? and (browserConfig.from instanceof Array) and browserConfig.from.length > 0
      log "browser data error",browserConfig
      socket.emit 'authenticated', error: "browser data error"
      setTimeout (-> socket.disconnect()),1000
      return

    browserConfig.from = (f for f in browserConfig.from when f?)
    socket.on 'disconnect', ->
      if browserConfig
        for s in browserConfig.from
          socket.leave "#{browserConfig.ns}:#{browserConfig.task.name}:#{s}"
        socket.leave "#{browserConfig.ns}:#{browserConfig.task.name}"
        log "browser leave"
      else
        log 'browser leave'

    socket.on 'attach', (data) ->
      log 'attach',data
      if data?.from? and (data.from instanceof Array)
        for worker in data.from when worker not in browserConfig.from
          socket.join "#{browserConfig.ns}:#{browserConfig.task.name}:#{worker}"
          browserConfig.from.push worker
          log "browser join room[#{browserConfig.ns}:#{browserConfig.task.name}:#{worker}]"

    socket.on 'detach', (data) ->
      log 'detach',data
      if data?.from? and (data.from instanceof Array)
        for worker in data.from when worker in browserConfig.from
          socket.leave "#{browserConfig.ns}:#{browserConfig.task.name}:#{worker}"
          log "browser leave room[#{browserConfig.ns}:#{browserConfig.task.name}:#{worker}]"
        browserConfig.from = (e for e in browserConfig.from when e not in data.from)

    socket.join "#{browserConfig.ns}:#{browserConfig.task.name}"
    log "browser join room[#{browserConfig.ns}:#{browserConfig.task.name}]"
    for s in browserConfig.from
      socket.join "#{browserConfig.ns}:#{browserConfig.task.name}:#{s}"
      log "browser join room[#{browserConfig.ns}:#{browserConfig.task.name}:#{s}]"
    
    socket.emit 'authenticated', browserConfig


module.exports = BrowserRouter
