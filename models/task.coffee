database = require './database'
debug = require 'debug'
log = debug 'ttServer:task'

Task = database.define 'Task',
  {
    name: { type: database.String,index: true }
    workers: { type: database.JSON }
    activeWorkers: { type: database.JSON }
    state: { type: database.String }
    lastActiveAt: { type: database.Date }
    startedAt: { type: database.Date }
  }

Task.beforeSave = (next) ->
  this.workers = [] unless this.workers
  this.activeWorkers = [] unless this.activeWorkers
  if this.workers?.length > 0
    if this.activeWorkers?.length > 0
      this.state = 'running'
    else
      this.state = 'stopped'
  else
    this.state = 'pending'
  this.lastActiveAt = new Date()
  this.startedAt = new Date() unless this.startedAt
  next()

module.exports = Task