express = require 'express'
debug = require 'debug'

jwtCfg = require('../config').jwt
jwt = require 'jsonwebtoken'

router = express.Router()
log = debug('http')

router.get '/', (req, res) ->
  res.render 'index',locals

router.get '/tasks/:name',(req,res) ->
  unless req.query.accessToken
    res.render 'error',message: '无accessToken'
    return
  jwt.verify req.query.accessToken, jwtCfg.browserToken.secret, (jwterr, payload) ->
    if payload?.type == 'browser_token'
      res.render 'task',name: req.params.name
    else if jwterr?.name == 'TokenExpiredError'
      res.render 'error',message: 'accessToken过期'
    else
      res.render 'error',message: '非法accessToken'

module.exports = router
