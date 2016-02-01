debug = require 'debug'
async = require 'async'
config = require '../config'
jwt = require 'jsonwebtoken'

jwtCfg = config.jwt
log = debug 'ttServer:client-router'

class ClientRouter
  forSocket: (socket,clientConfig) ->
    unless /^[\da-zA-Z][\d_-a-zA-Z\.]*/.test clientConfig.task.name
      log "task name[#{clientConfig.task.name}]contains invalid name!"
      socket.emit 'authenticated', error: "invalid task name[#{clientConfig.task.name}], task name can only have '.-_a-zA-Z' and start with chars!"
      setTimeout (-> socket.disconnect()),1000
      return
    
    # set room
    clientConfig.room = "#{clientConfig.task.name}:#{clientConfig.id}"
    async.waterfall [
      (cb) ->
        socket.in(clientConfig.task.name).emit 'workerIn', from: clientConfig.id
        setTimeout cb,500
      (cb) ->
        socket.in(clientConfig.room).emit 'start',
          from: clientConfig.id
          task: clientConfig.task
        log "monitor client(#{clientConfig.id})for task[#{clientConfig.task.name}]"
        log clientConfig.task.cmd
        cb()
    ], (err) ->
      browserPayload =
        type: 'browser_token'
      browserToken = jwt.sign browserPayload, jwtCfg.browserToken.secret, jwtCfg.browserToken.options
      log jwtCfg.browserToken.secret
      log browserToken    
      socket.emit 'authenticated',
        httpUrl: "#{config.me.host}/tasks/#{clientConfig.task.name}/?accessToken=#{browserToken}&id=#{clientConfig.id}"

    socket.on 'data', (data) ->
      log 'got data:',data
      socket.in(clientConfig.room).emit 'data',from: clientConfig.id,data: data

    socket.on 'eof', (data) ->
      log "client:#{clientConfig.id},task:#{clientConfig.task.name} exit with #{data.code}"
      socket.in(clientConfig.room).emit 'eof',
        from: clientConfig.id
        code: data.code
        signal: data.signal
      socket.emit 'bye',
        code: data.code
        signal: data.signal
      setTimeout (-> socket.disconnect()),5000
      

    socket.on 'disconnect', ->
      if clientConfig
        socket.in(clientConfig.task.name).emit 'workerOut', from: clientConfig.id
        log "#{clientConfig.id} leave"
      else
        log 'client leave'

module.exports = ClientRouter
