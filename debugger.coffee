((location, console) ->
  re = ///(^|\?|&)#{console.debugSwatch or "debug"}(&|=|$)///
  enableDebug = location.search.match re
  console.log ?= ->

  console.debugger = ->
    return unless enableDebug or console.debugMode
    debugger

  holder = (method, fn) -> ->
    return unless enableDebug or console.debugMode
    if fn
      fn.apply console, arguments
    else
      console.log "[#{method}]:", arguments...

  methods = """
    log
    dir
    info
    warn
    error
    debug
    trace
    count
    assert
    dirxml
    exception
    markTimeline
    groupCollapsed
    group
    groupEnd
    profile
    profileEnd
    time
    timeEnd
  """.split /\s/

  while method = methods.pop()
    console[method] = holder method, console[method]

  if window.Proxy
    # http://wiki.ecmascript.org/doku.php?id=harmony:direct_proxies
    # https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Proxy
    window.console = new Proxy console,
      get: (target, name, receiver) ->
        if name in Object.getOwnPropertyNames(target)
          target[name]
        else
          holder name
  else
    # https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/noSuchMethod
    console.__noSuchMethod__ = (name, args) ->
      (holder name) args...

) window.location, window.console or= {}
