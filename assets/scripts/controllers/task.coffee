$ = require 'jquery-browserify'
bootstrap = require 'bootstrap'
toastr = require 'toastr'
socketio = require 'socket.io-client'
urlPrase = require 'url-parse'
$ ->
  jobInfo = 
    workers: []

  url = urlPrase window.location.href,true
  token = url.query.accessToken

  watchConfig = {}
  socket = socketio "#{window.location.protocol}//#{window.location.host}"
  socket.on 'connect', ->
    socket.emit 'authenticate',
      type: 'browser_token'
      token: token
      watch:
        task: (e for e in url.pathname.split('/') when e.length > 0)[1]
        from: [ url.query.id ]

  socket.on 'authenticated', (data) ->
    console.log "authenticated data:",data
    if data.error
      $('p.shell-top-bar').text data.error
    else
      $('p.shell-top-bar').text "任务名称: #{data.task.name} 来源: #{data.from[0]}"
      $('td.tname').text data.task.name
      $('td.tsource').text data.from[0]
      watchConfig.target = data.from[0]
  
  socket.on 'start',(data) ->
    console.log "task info",data
    if data.from == watchConfig.target
      $('.modal-cmd').text data.task.cmd
      $('.modal-title').text "任务#{data.task.name}命令内容"
      if data.task.cmd.length > 25
        showCmd = data.task.cmd[0..24] + '...'
        $('td.tcmd').html "<a href data-toggle='modal' data-target='#myModal'>#{showCmd}</a>"
      else 
        showCmd = data.task.cmd
        $('td.tcmd').html showCmd
      
      $('td.tstate').text '执行中...'

  socket.on 'data',(data) ->
    console.log "got",data
    if data.from == watchConfig.target
      for line in data.data.data.split("\n")
        $('ul.shell-body').append "<li>#{line}</li>"
      $('ul.shell-body').scrollTop($('ul.shell-body')[0].scrollHeight)

  socket.on 'eof', (data) ->
    console.log 'eof',data
    if data.from == watchConfig.target
      if data.code == 0
        msg = '任务成功完成'
      else
        msg = "执行结束, 退出码: #{data.code}"
        msg += ",终止信号: #{data.signal}" if data.signal
      $('td.tstate').text msg
      $('ul.shell-body').append "<li class='cursor'>#{msg}!</li>"
      $('ul.shell-body').scrollTop($('ul.shell-body')[0].scrollHeight)

  socket.on 'workerIn', (data) ->
    console.log "worker in",data
    jobInfo.workers.push data.from
    $('td.tsourceNum').text jobInfo.workers.length

  socket.on 'workerOut', (data) ->
    console.log "worker lost",data
    jobInfo.workers = (w for w in jobInfo.workers when w != data.from)
    $('td.tsourceNum').text jobInfo.workers.length
    if data.from == watchConfig.target
      $('td.tstate').text "异常终止" if /执行中/.test $('td.tstate').text()


