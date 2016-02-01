express = require 'express'
debug = require 'debug'

jwtCfg = require('../config').jwt
jwt = require 'jsonwebtoken'

router = express.Router()
log = debug('http')

router.get '/', (req, res) ->
  unless req.query.accessToken
    res.render 'error',message: 'no accessToken found'
    return
  jwt.verify req.query.accessToken, jwtCfg.browserToken.secret, (jwterr, payload) ->
    if payload?.type == 'browser_token'
      res.render 'index'
    else if jwterr?.name == 'TokenExpiredError'
      res.render 'error',message: 'accessToken expired'
    else
      res.render 'error',message: 'invalid accessToken'    

router.get '/tasks/:name',(req,res) ->
  unless req.query.accessToken
    res.render 'error',message: 'no accessToken found'
    return
  jwt.verify req.query.accessToken, jwtCfg.browserToken.secret, (jwterr, payload) ->
    if payload?.type == 'browser_token'
      res.render 'task',name: req.params.name
    else if jwterr?.name == 'TokenExpiredError'
      res.render 'error',message: 'accessToken expired'
    else
      res.render 'error',message: 'invalid accessToken'

module.exports = router
