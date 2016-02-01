$ = require 'jquery-browserify'
bootstrap = require 'bootstrap'
toastr = require 'toastr'
urlPrase = require 'url-parse'

$ ->
  $('button.start-trace').on 'click', ->
    url = urlPrase window.location.href,true
    console.log url
    token = url.query.accessToken
    name = $('input#task-name').val()
    if name?.length > 0 and /^[\da-zA-Z][\d_-a-zA-Z\.]*/.test(name)
      url.pathname = "/tasks/#{name}"
      window.location.href = url.toString()
    else
      toastr.error 'invalid task name'


