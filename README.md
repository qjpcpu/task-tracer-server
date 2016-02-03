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

## Interfaces

Intergrate tt into your app is easy. Implement interfaces below with [sockt.io](http://socket.io/)

### ttServer interfaces
### 1. authenticate

Trigger `authenticate` event on server, better to trigger this event when connected to ttServer.

```
socket.on('connect', function() {
  return socket.emit('authenticate', {
    type: 'browser_token',
    token: 'YOUR Browser token',
    watch: {
      task: 'test',
      from: ['client-id']
    }
  });
});
```
### 2. attach,detach

Trace task from certain client, tell ttServer you want `attach`; Otherwise, `detach` from certain client if not to trace anymore.

```
socket.emit('attach', {
  from: ['client-id2', 'client-id3']
});

socket.emit('detach', {
  from: ['client-id3']
});
```

### local interfaces

### 1. authenticated

when ttServer complete authentication,the `authenticated` event would be triggered.

```
socket.on('authenticated', function(data) {
  if (data.error) {
    return console.log(data.error);
  } else {
    return console.log('auth OK');
  }
});
```

### 2. start

Certain client start to run task.

```
socket.on('start', function(data) {
  return console.log(data.from + " start to run");
});
```

### 3. data

New data from client comming.

```
socket.on('data', function(msg) {
  console.log("new " + msg.data.type + " data from: " + msg.from);
  return console.log(msg.data.data);
});
```

### 4. eof

Task finish on certain client.

```
socket.on('eof', function(msg) {
  console.log(msg.from + " finish!");
  console.log("Exit code=" + msg.code);
  if (msg.signal) {
    return console.log(msg.from + " exit because signal " + msg.signal);
  }
});
```

### 5. workerIn/workerOut

When client connected/disconnected to/from ttServer, your browser would get this event.

```
socket.on('workerIn', function(data) {
  return console.log(data.from + " come and ready for task");
});

socket.on('workerOut', function(data) {
  return console.log(data.from + " leave");
});
```
