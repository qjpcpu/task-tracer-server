mkdirp = require 'mkdirp'
fs = require 'fs'
path = require 'path'
CSON = require 'cson'
debug = require 'debug'

log = debug 'ttServer:config'
mkdirp.sync path.join(__dirname,'rc')

config =
  me:
    host: 'http://localhost:8004'
  redis:
    host: "localhost"
    port: '6379'
    db: 7
  jwt:
    clientToken:
      secret: '9dd4cd'
      options:
        algorithm: 'HS256'
        expiresIn: '1 year' # expressed in seconds or an string describing a time span rauchg/ms. Eg: 60, "2 days", "10h", "7d"
    browserToken:
      secret: 'f6e'
      options:
        algorithm: 'HS256'
        expiresIn: '1 day' # expressed in seconds or an string describing a time span rauchg/ms. Eg: 60, "2 days", "10h", "7d"

filename = path.join __dirname,'rc/real-config.json'

try
  fs.statSync filename
  config = CSON.parseJSONFile filename
catch err
  confStr = CSON.createJSONString config
  fs.writeFile filename, confStr, (werr) ->
    log "dump config to #{filename}"

module.exports = config
