EventEmitter = require('events').EventEmitter


class MjpgEmitter extends EventEmitter
  constructor: (@emitAfter=5000, boundary='mjpgemitter') ->
    # emitAfter is in milliseconds
    @buffers = []
    @boundaryName = boundary
    @boundary = "--#{boundary}"

  start: ->
    if @timeoutId then throw new Error('already started')
    @timeoutId = setTimeout(@flush, @emitAfter)

  stop: ->
    clearTimeout(@timeoutId)
    @timeoutId = undefined

  flush: =>
    @stop()
    @flushing = true
    bufferOut = @buffer()
    headers   = @headers(bufferOut)
    @emit 'image', bufferOut, headers
    @flushing = false
    @buffers = []
    @start()

  add: (buffer) ->
    @start() if not @timeoutId
    if not @flushing
      @_writeHeader(buffer)
      @buffers.push(buffer)
    else
      @emit 'message', 'flushing'

  buffer: -> Buffer.concat(@buffers)

  headers: (buffer) ->
    'content-type': "multipart/x-mixed-replace;boundary=#{@boundaryName}"
    'content-length': buffer.length

  _writeHeader: (buffer) ->
    @buffers.push(@_headerForBuffer(buffer))

  _headerForBuffer: (buffer) ->
    string = """
             #{@boundary}
             Content-Type: image/jpeg
             Content-Length: #{buffer.length}
             \n
             """
    new Buffer(string)


module.exports = MjpgEmitter
