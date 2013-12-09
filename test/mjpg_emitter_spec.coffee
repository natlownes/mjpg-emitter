require './setup'
fs = require 'fs'
testjpg = fs.readFileSync('./test/fixtures/test.jpg')

MjpgEmitter = require '../src/index'


describe 'MjpgEmitter', ->

  describe 'constructor', ->

    context 'with emitAfter arg [0]', ->
      it 'should default to 5000 milliseconds', ->
        mjpg = new MjpgEmitter

        expect( mjpg.emitAfter ).to.equal 5000

      it 'should set @emitAfter if set', ->
        mjpg = new MjpgEmitter(2000)

        expect( mjpg.emitAfter ).to.equal 2000

    context 'optional 2nd arg:  boundary', ->
      it 'should default to "mjpgemitter"', ->
        mjpg = new MjpgEmitter

        expect( mjpg.boundary ).to.equal '--mjpgemitter'

      it 'should be able to set @boundary to value used in buffer', ->
        mjpg = new MjpgEmitter(5000, 'customboundary')

        expect( mjpg.boundary ).to.equal '--customboundary'

      it 'should be able to set @boundaryName', ->
        mjpg = new MjpgEmitter(5000, 'customboundary')

        expect( mjpg.boundaryName ).to.equal 'customboundary'


  describe '#start', ->
    it 'should set @timeoutId', ->
      mjpg = new MjpgEmitter

      mjpg.start()

      expect( mjpg.timeoutId ).to.exist

      mjpg.stop()

    context 'after timeout expires', ->
      beforeEach ->
        @clock = sinon.useFakeTimers()

      afterEach ->
        @clock.restore()

      it 'should call #flush after @emitAfter', ->
        mjpg = new MjpgEmitter(2000)
        flush = sinon.spy(mjpg, 'flush')
        mjpg.start()

        @clock.tick(2000)

        expect( flush ).to.have.been.calledOnce

        mjpg.stop()


  describe '#stop', ->
    beforeEach ->
      @clock = sinon.useFakeTimers()

    afterEach ->
      @clock.restore()

    it 'should clearTimeout', ->
      mjpg = new MjpgEmitter(2000)
      flush = sinon.spy(mjpg, 'flush')
      mjpg.start()

      mjpg.stop()

      @clock.tick(2000)

      expect( flush ).not.to.have.been.called

  describe 'flush', ->

    it 'should call #stop', ->
      mjpg = new MjpgEmitter
      stop = sinon.spy(mjpg, 'stop')

      mjpg.flush()

      expect( stop ).to.have.been.called

      # manually clearTimeout
      clearTimeout(mjpg.timeoutId)

    it 'should emit an "image" event with the buffer', (done) ->
      mjpg           = new MjpgEmitter(1000)
      expectedBuffer = testjpg
      mjpg.add(expectedBuffer)

      mjpg.on 'image', (buffer, headers) ->
        expect( buffer.toString() ).to.contain expectedBuffer.toString()
        done()

      mjpg.flush()
      mjpg.stop()

    it 'should emit an "image" event with the HTTP headers', (done) ->
      mjpg           = new MjpgEmitter(1000)
      expectedBuffer = testjpg
      mjpg.add(expectedBuffer)

      mjpg.on 'image', (buffer, headers) ->
        expect( headers['content-type'] )
          .to.equal 'multipart/x-mixed-replace;boundary=mjpgemitter',

        expect( headers['content-length'] )
          .to.equal buffer.length

        done()

      mjpg.flush()
      mjpg.stop()

    it 'should set @buffers back to empty array', ->
      mjpg = new MjpgEmitter(1000)
      mjpg.add testjpg

      mjpg.flush()

      expect( mjpg.buffers ).to.be.empty
      mjpg.stop()

    it 'should call #start', ->
      mjpg = new MjpgEmitter(1000)
      start = sinon.spy(mjpg, 'start')

      mjpg.flush()

      expect( start ).to.have.been.called

      mjpg.stop()

  describe '#add', ->

    context 'when not flushing', ->
      mjpgSetup = ->
        o = new MjpgEmitter
        o.flushing = false
        o

      it 'should write the boundary to the buffer', ->
        mjpg = mjpgSetup()

        testBuffer = testjpg

        mjpg.add(testBuffer)
        header = mjpg.buffers[0]

        expect( header.toString() ).to.contain '--mjpgemitter'

      it 'should write the Content-Type to the buffer', ->
        mjpg = mjpgSetup()

        testBuffer = testjpg

        mjpg.add(testBuffer)
        header = mjpg.buffers[0]

        expect( header.toString() ).to.contain 'Content-Type: image/jpeg'

      it 'should write the Content-Length to the buffer', ->
        mjpg = mjpgSetup()

        testBuffer = testjpg

        mjpg.add(testBuffer)
        header = mjpg.buffers[0]

        expect( header.toString() ).to.contain "Content-Length: #{testBuffer.length}"

      it 'should push the buffer arg into the buffers array', ->
        mjpg = mjpgSetup()

        testBuffer = testjpg

        mjpg.add(testBuffer)
        imageBuffer = mjpg.buffers[1]

        expect( imageBuffer ).to.equal testBuffer

      context 'when timer has not been started', ->

        it 'should call start on #add', ->
          mjpg = mjpgSetup()

          expect(mjpg.timeoutId).to.not.exist

          testBuffer = testjpg

          mjpg.add(testBuffer)

          expect(mjpg.timeoutId).to.exist

    context 'when flushing', ->
      mjpgSetup = ->
        o = new MjpgEmitter
        o.flushing = true
        o

      it 'should emit a "message" event with "flushing" as the arg', (done) ->
        mjpg = mjpgSetup()

        mjpg.on 'message', (msgString) ->
          expect( msgString ).to.equal 'flushing'
          done()

        mjpg.add(testjpg)

  describe '#buffers', ->

    it 'should concat the @buffers array', ->
      mjpg = new MjpgEmitter

      mjpg.add(testjpg)

      expect( mjpg.buffer().toString() )
        .to.equal Buffer.concat(mjpg.buffers).toString()

  describe 'headers', ->

    it 'should return an object with HTTP headers for the given buffer', ->
      mjpg = new MjpgEmitter

      mjpg.add(testjpg)

      headers = mjpg.headers(mjpg.buffer())

      expect( headers['content-type'] )
        .to.equal 'multipart/x-mixed-replace;boundary=mjpgemitter'

      expect( headers['content-length'] ).to.equal mjpg.buffer().length

