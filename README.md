# mjpg-emitter

[![Build
Status](https://travis-ci.org/natlownes/mjpg-emitter.png?branch=master)](https://travis-ci.org/natlownes/mjpg-emitter)

Take several jpgs and make them into an mjpg.  The idea is that you can chuck
jpgs into this and get an mjpg emitted after the time (in milliseconds) you
specify in the constructor.  An optional second argument is the mjpg boundary
string.

There's not an mjpg standard, but I've done my best to just copy what other
devices I've encountered have outputted.  MJPG is funny, [you can read about it
here](http://en.wikipedia.org/wiki/Motion_JPEG).  The idea is that it's one big
file with several jpgs, delimited by a 'Content-Type' and 'Content-Length'
headers and then a newline.  Browsers can handle this as a motion jpg if you
send it with a "Content-Type" header of
"multipart/x-mixed-replace;boundard=mjpgemitter" and a "Content-Length" of
whatever the length of the emmitted buffer is.  These headers will be emitted as
the 2nd argument to "image" listeners.

## installation

```

npm install mjpg-emitter

```

## usage

It will emit an 'image' event when your mjpg is ready - "ready" is defined as
*the amount of milliseconds you've specified in the constructor have passed*.
So chuck in however many jpgs you want, get back an mjpg stream of those after
however many milliseconds.

```javascript

MjpgEmitter= = require('mjpg-emitter')

mjpgs = new MjpgEmitter(10000)

mjpgs.on('image', function(buffer, headers) {
  // buffer is a buffer, headers is a js object
  // if you wanted to serve this, you would set "headers"
  // as your HTTP headers and then spit out "buffer"
  // as the body
})

while(true) {
  // return a jpg here
  var buffer = getYourJpg()

  mjpgs.add(buffer)
}

```

## todo
* conform to 0.10 streams interface
