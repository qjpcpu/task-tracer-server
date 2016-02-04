$ = require 'jquery-browserify'
bootstrap = require 'bootstrap'
toastr = require 'toastr'
socketio = require 'socket.io-client'
urlPrase = require 'url-parse'
$ ->
  jobInfo = 
    workers: {}
    flushDom: (wid) ->
      ji = this
      return unless ji.workers[wid]
      worker = ji.workers[wid]
      if worker.doms
        worker.doms.light.getElementsByTagName('input')[0].checked = worker.visible
        if worker.active
          worker.doms.light.getElementsByClassName('twinkle')[0].setAttribute 'class','twinkle twinkle-on'
        else
          worker.doms.light.getElementsByClassName('twinkle')[0].setAttribute 'class','twinkle'
        if worker.visible
          unless worker.doms.terminal?
            termDom = document.createElement "div"
            termDom.setAttribute 'class',"row term-#{wid}"
            termDom.innerHTML = "
              <div class='col-lg-12'>
                <div class='shell-wrap'>
                  <div class='titlebar'>
                    <div class='buttons'>
                      <div class='close'>
                        <a class='closebutton' href='javascript:void(0)' id='#{wid}'><span><strong>x</strong></span></a>
                      </div>
                    </div>
                    node: #{wid}
                  </div>
                  <ul class='shell-body'>
                    <li class='cursor'>loading output......</li>
                  </ul>
                </div>
              </div>"
            worker.doms.terminal = termDom
            _cssTermParent = document.getElementsByClassName('terminals')[0]
            _cssTermParent.appendChild worker.doms.terminal
            $('input.worker-visible').off('change').on 'change', ->
              id = $(this).attr('name')
              if id and jobInfo.workers[id]
                w = jobInfo.workers[id]
                jobInfo.workers[id].visible = $(this).is(':checked')
                jobInfo.flushDom id
                if jobInfo.socket
                  if w.visible
                    jobInfo.socket.emit 'attach',from: [id]
                  else
                    jobInfo.socket.emit 'detach',from: [id]
            $('a.closebutton').off('click').on 'click', ->
              id = $(this).attr('id')
              if id and jobInfo.workers[id]
                jobInfo.workers[id].visible = false
                jobInfo.flushDom id
                if jobInfo.socket
                  jobInfo.socket.emit 'detach',from: [id]        
          else
            $(worker.doms.terminal).show('fast')
        else if worker.doms.terminal?
            $(worker.doms.terminal).hide('fast')
      else
        worker.doms = {}
        # create twinkle light
        lightDom = document.createElement "li"
        lightDom.id = wid
        _div = document.createElement 'div'
        _div.setAttribute 'class','twinkle'
        lightDom.appendChild _div
        _input = document.createElement 'input'
        _input.type = 'checkbox'
        _input.name = wid
        _input.setAttribute 'class','worker-visible'
        _input.checked = worker.visible
        lightDom.appendChild _input
        _a = document.createElement 'a'
        _a.href = 'javascript:void(0)'
        _a.setAttribute 'class','worker-detail'
        _a.text = wid
        lightDom.appendChild _a
        # create terminal window
        if worker.visible
          termDom = document.createElement "div"
          termDom.setAttribute 'class',"row term-#{wid}"
          termDom.innerHTML = "
            <div class='col-lg-12'>
              <div class='shell-wrap'>
                <div class='titlebar'>
                  <div class='buttons'>
                    <div class='close'>
                      <a class='closebutton' href='javascript:void(0)' id='#{wid}'><span><strong>x</strong></span></a>
                    </div>
                  </div>
                  node: #{wid}
                </div>
                <ul class='shell-body'>
                  <li class='cursor'>loading output......</li>
                </ul>
              </div>
            </div>"
          worker.doms.terminal = termDom
        worker.doms.light = lightDom
        # write to html
        _cssParent = document.getElementsByClassName('workers-list')[0]
        _cssParent.appendChild lightDom
        $('a.worker-detail').off('click').on 'click', ->
          workerId = $(this).text()
          task = jobInfo.workers[workerId].task
          $('.modal-cmd').text task?.cmd or '[node not connected]'
          $('.modal-title').text "node: #{workerId}"
          $('#myModal').modal 'show'
        if worker.visible
          _cssTermParent = document.getElementsByClassName('terminals')[0]
          _cssTermParent.appendChild worker.doms.terminal
          $('a.closebutton').off('click').on 'click', ->
            id = $(this).attr('id')
            if id and jobInfo.workers[id]
              jobInfo.workers[id].visible = false
              jobInfo.flushDom id
              if jobInfo.socket
                jobInfo.socket.emit 'detach',from: [id]        
       $('input.worker-visible').off('change').on 'change', ->
         id = $(this).attr('name')
         if id and jobInfo.workers[id]
           w = jobInfo.workers[id]
           jobInfo.workers[id].visible = $(this).is(':checked')
           jobInfo.flushDom id
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
    jobInfo.flushDom url.query.id

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
    if jobInfo.workers[data.from]
      jobInfo.workers[data.from].active = true
      jobInfo.workers[data.from].doms.light.getElementsByClassName('twinkle')[0].classList.add 'twinkle-on'
    else
      jobInfo.workers[data.from] = 
        from: data.from
        active: true
        visible: false
      jobInfo.flushDom data.from

  socket.on 'workerOut', (data) ->
    return unless jobInfo.workers[data.from]
    jobInfo.workers[data.from].active = false
    jobInfo.workers[data.from].doms.light.getElementsByClassName('twinkle')[0].classList.remove 'twinkle-on'

  headBar =
    state: document.getElementsByClassName("tstate")[0]
    count: document.getElementsByClassName("tsourceNum")[0]
  setInterval (->
    nodeCnt = (w for w,x of jobInfo.workers when x.active).length
    headBar.count.innerHTML = nodeCnt
    activeCnt = (w for w,x of jobInfo.workers when x.active).length
    if activeCnt > 0
      headBar.state.innerHTML = 'running'
    else
      headBar.state.innerHTML = 'task finished'    
  ),500


