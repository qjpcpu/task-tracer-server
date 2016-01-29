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
      socket.disconnect()
      return

    socket.on 'disconnect', ->
      if browserConfig
        for s in browserConfig.from
          socket.leave "#{browserConfig.task.name}:#{s}"
        socket.leave "#{browserConfig.task.name}"
        log "browser leave"
      else
        log 'browser leave'

    socket.join "#{browserConfig.task.name}"
    for s in browserConfig.from
      socket.join "#{browserConfig.task.name}:#{s}"
      log "browser join room:#{browserConfig.task.name}:#{s}"
    
    socket.emit 'authenticated', browserConfig


module.exports = BrowserRouter
