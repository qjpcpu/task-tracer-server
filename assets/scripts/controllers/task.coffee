$ = require 'jquery-browserify'
bootstrap = require 'bootstrap'
toastr = require 'toastr'
socketio = require 'socket.io-client'
urlPrase = require 'url-parse'
$ ->
  jobInfo = 
    workers: {}

  flushWorkers =  (from,w) ->
    if $(".workers-list li##{from} .twinkle").length > 0
      if w.active
        $(".workers-list li##{from} .twinkle").addClass('twinkle-on')
      else
        $(".workers-list li##{from} .twinkle").removeClass('twinkle-on')
      $(".workers-list li##{from} input.worker-visible").prop "checked", w.visible 
    else
      style = if w.active then 'twinkle-on' else ''
      workerVisible = if w.visible then 'checked' else ''
      $(".workers-list").append "<li id='#{from}'>
      <div class='twinkle #{style}'></div>
      <input type='checkbox' name='#{from}' class='worker-visible' #{workerVisible}>
      <a href='#' class='worker-detail'>#{from}</a>
      </li>"
    if $(".terminals .term-#{from}").length == 0 and w.visible
      htmlStr = "<div class='row term-#{from}'>
        <div class='col-lg-12'>
          <div class='shell-wrap'>
            <div class='titlebar'>
              <div class='buttons'>
                <div class='close'>
                  <a class='closebutton' href='#' id='#{from}'><span><strong>x</strong></span></a>
                </div>
              </div>
              node: #{from}
            </div>
            <ul class='shell-body'>
              <li class='cursor'>loading output......</li>
            </ul>
          </div>
        </div>
      </div><br/>"
      $('.terminals').append htmlStr
    act = if w.visible then 'show' else 'hide'
    $(".terminals .term-#{from}")[act]('fast')

    $('a.worker-detail').off('click').on 'click', ->
      workerId = $(this).text()
      task = jobInfo.workers[workerId].task
      $('.modal-cmd').text task?.cmd or '[node not connected]'
      $('.modal-title').text "node: #{workerId}"
      $('#myModal').modal 'show'
    $('a.closebutton').off('click').on 'click', ->
      id = $(this).attr('id')
      if id and jobInfo.workers[id]
        jobInfo.workers[id].visible = false
        flushWorkers(id,jobInfo.workers[id])
        if jobInfo.socket
          jobInfo.socket.emit 'detach',from: [id]        
    $('input.worker-visible').off('change').on 'change', ->
      id = $(this).attr('name')
      if id and jobInfo.workers[id]
        jobInfo.workers[id].visible = $(this).is(':checked')
        flushWorkers(id,jobInfo.workers[id])
        if jobInfo.socket
          if w.visible
            jobInfo.socket.emit 'attach',from: [id]
          else
            jobInfo.socket.emit 'detach',from: [id]


  url = urlPrase window.location.href,true
  token = url.query.accessToken

  if url.query.id
    jobInfo.workers[url.query.id] = 
      from: url.query.id
      active: false
      visible: true
    flushWorkers(url.query.id,jobInfo.workers[url.query.id])

  socket = socketio "#{window.location.protocol}//#{window.location.host}"
  socket.on 'connect', ->
    socket.emit 'authenticate',
      type: 'browser_token'
      token: token
      watch:
        task: (e for e in url.pathname.split('/') when e.length > 0)[1]
        from: [ url.query.id ]

  socket.on 'authenticated', (data) ->
    if data.error
      $('p.shell-top-bar').text data.error
    else
      jobInfo.socket = socket
  
  socket.on 'start',(data) ->
    if jobInfo.workers[data.from]
      jobInfo.workers[data.from].task = data.task

  socket.on 'data',(data) ->
    if jobInfo.workers[data.from]
      style = if data.data.type == 'STDERR' then 'stderr' else 'stdout'
      for line in data.data.data.split("\n")
        $(".terminals .term-#{data.from} ul.shell-body").append "<li class='#{style}'>#{line}</li>"
      $(".terminals .term-#{data.from} ul.shell-body").scrollTop($(".terminals .term-#{data.from} ul.shell-body")[0].scrollHeight)

  socket.on 'eof', (data) ->
    console.log 'eof',data
    if jobInfo.workers[data.from]
      if data.code == 0
        msg = 'task finished with success'
      else
        msg = "task finished, exit code: #{data.code}"
        msg += ",exit signal: #{data.signal}" if data.signal
      $(".terminals .term-#{data.from} ul.shell-body").append "<li class='cursor'>#{msg}!</li>"
      $(".terminals .term-#{data.from} ul.shell-body").scrollTop($(".terminals .term-#{data.from} ul.shell-body")[0].scrollHeight)

  socket.on 'workerIn', (data) ->
    console.log "worker in",data
    unless jobInfo.workers[data.from]
      jobInfo.workers[data.from] =
        from: data.from
        active: true
        visible: false
    onlyOne = (w for w,x of jobInfo.workers).length == 1
    jobInfo.workers[data.from].active = true
    jobInfo.workers[data.from].visible = true if onlyOne
    flushWorkers(data.from,jobInfo.workers[data.from])
    $('td.tsourceNum').text (w for w,x of jobInfo.workers when x.active).length
    if (w for w,x of jobInfo.workers when x.active).length > 0
      $('td.tstate').text 'running...'
    else
      $('td.tstate').text 'task finished'    

  socket.on 'workerOut', (data) ->
    console.log "worker lost",data
    for w,x of jobInfo.workers
      x.active = false if w == data.from
    flushWorkers(data.from,jobInfo.workers[data.from])
    $('td.tsourceNum').text (w for w,x of jobInfo.workers when x.active).length
    if (w for w,x of jobInfo.workers when x.active).length > 0
      $('td.tstate').text 'running...'
    else
      $('td.tstate').text 'task finished'


