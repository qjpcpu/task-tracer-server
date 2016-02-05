debug = require 'debug'
async = require 'async'
jwt = require 'jsonwebtoken'
jwtCfg = require('../config').jwt
ClientRouter = require './client-router'
BrowserRouter = require './browser-router'
log = debug 'ttServer:socket-server'

SocketServer = 
  io: null
  get: -> @io
  set: (sio) -> 
    @io = sio
    @io.on 'connection', (socket) ->
      # authentication
      socket.auth = false
      socket.on 'authenticate', (data) ->
        socket.auth = true
        log 'got token',data
        secret = if data.type == 'client' then jwtCfg.clientToken.secret else jwtCfg.browserToken.secret
        jwt.verify data.token, secret, (jwterr, payload) ->
          if payload
            switch payload.type
              when 'client_token'
                log "client authenticate OK",payload
                new ClientRouter().forSocket socket,
                  id: data.id
                  task: data.task
                  ns: payload.ns or ''
              when 'browser_token'
                log 'browser authenticate OK',payload
                new BrowserRouter().forSocket socket,
                  task: name: data.watch.task
                  from: data.watch.from
                  ns: payload.ns or ''
              else
                log "invalid payload",payload
                socket.disconnect()
          else if jwterr?.name == 'TokenExpiredError'
            log 'client token expired'
            socket.disconnect()
          else
            log "unknown token: #{data.token}",jwterr
            socket.disconnect()
 
      setTimeout (->
        unless socket.auth
          log "disconnecting socket ", socket.id
          socket.disconnect()
      ), 5000
      log 'client connected'

module.exports = SocketServer
