express = require 'express'
debug = require 'debug'
async = require 'async'
jwt = require 'jsonwebtoken'
jwtCfg = require('../config').jwt
Cc = require 'change-case'

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

router.post '/tokens/generate', (req,res) ->
  async.waterfall [
    (cb) ->
      if req.body.baseToken?.length > 0
        jwt.verify req.body.baseToken, jwtCfg.baseToken.secret, (jwterr, payload) ->
          if payload.type == 'base_token' and payload.ns?.length > 0
            cb(null,payload.ns)
          else if jwterr?.name == 'TokenExpiredError'
            cb "#{req.body.baseToken} has already expired!"
          else
            cb 'Invalid base token'
      else
        cb 'no base token found'
    (ns,cb) ->
      genToken = (tokenType) ->
        period = (if req.query.days? and req.query.days.toString() in ['7','30','180','360'] then parseInt(req.query.days) else 180)
        period = "#{period} days"
        payload =
          type: Cc.snake(tokenType)
          ns: ns
        options = 
          algorithm: jwtCfg[tokenType].options.algorithm
          expiresIn: period
        jwt.sign payload,jwtCfg[tokenType].secret, options

      tokens = {}
      if req.query.type?.length > 0 and req.query.type in ['clientToken','browserToken','baseToken']
        tokens[req.query.type] = genToken req.query.type
        cb null,tokens
      else
        tokens.clientToken = genToken 'clientToken'
        tokens.browserToken = genToken 'browserToken'
        cb null,tokens      
  ], (err,tokens) ->
    if err then res.status(400).json error: err else res.json tokens

module.exports = router
