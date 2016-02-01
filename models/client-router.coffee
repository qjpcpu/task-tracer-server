debug = require 'debug'
async = require 'async'
config = require '../config'
jwt = require 'jsonwebtoken'

jwtCfg = config.jwt
log = debug 'ttServer:client-router'

class ClientRouter
  forSocket: (socket,clientConfig) ->
    unless /^[\da-zA-Z][\d_-a-zA-Z\.]*/.test clientConfig.task.name
      log "任务名称[#{clientConfig.task.name}]包含特殊字符!"
      socket.emit 'authenticated', error: "任务名称[#{clientConfig.task.name}]非法,仅能包含字母数字及'.-_'且以字母或数字开头!"
      socket.disconnect()
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
        log "监控client(#{clientConfig.id})执行任务[#{clientConfig.task.name}]"
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
      log "client:#{clientConfig.id},任务:#{clientConfig.task.name} exit with #{data.code}"
      socket.in(clientConfig.room).emit 'eof',
        from: clientConfig.id
        code: data.code
        signal: data.signal
      socket.disconnect()

    socket.on 'disconnect', ->
      if clientConfig
        socket.in(clientConfig.task.name).emit 'workerOut', from: clientConfig.id
        log "#{clientConfig.id} leave"
      else
        log 'client leave'

module.exports = ClientRouter
