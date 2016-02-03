TaskTracer(client) - Real-time process monitoring
=================================================

Powered by [node.js](http://nodejs.org) + [socket.io](http://socket.io)

## How does it work?
*tt(task tracer client)* capture process output(both stdout & stderr) and send the data to *ttServer* via socket.io, browser or your own socketio client can get these data via socket.io realtime.

## Install

```
# install nodejs & npm first
git clone git@github.com:qjpcpu/task-tracer-server.git
cd task-tracer-server && npm install && gulp build
npm install pm2 -g
```

## Configuration

config file `./rc/real-config.json`

```
{
  "me": {
    "host": "http://tt-server.com"
  },
  /**
   * Uncomment redis config if you need
   */
  /**
  "redis": {
    "host": "localhost",
    "port": "6379",
    "db": 7
  },
  */
  "jwt": {
    "clientToken": {
      "secret": "zxw",
      "options": {
        "algorithm": "HS256",
        "expiresIn": "1 year"
      }
    },
    "browserToken": {
      "secret": "eeg",
      "options": {
        "algorithm": "HS256",
        "expiresIn": "1 day"
      }
    }
  }
}
```

## Run

```
# start server
cd task-tracer-server && ./control start
```

## Generate tokens

```
# follow instructions to generate browser/client token
cd task-tracer-server && ./bin/tokengen
```

## Watch task output

Navigation your browser to `http://tt-server.com/?accessToken=BR`(config.me.host)

Trace task `test`

![index.png](https://raw.githubusercontent.com/qjpcpu/task-tracer-server/master/snapshots/index.png)

Launch task from client

```
$ TASK_TRACER_NAME=test ./dist/tt 'echo hello browser;sleep 1;echo "I am `whoami`"'
View https://tt.iop.tap4fun.com/tasks/test/?accessToken=eyJ0eXAi&id=i-7361c17d for task output
hello browser
I am ubuntu
```

![output.png](https://raw.githubusercontent.com/qjpcpu/task-tracer-server/master/snapshots/output.png)
