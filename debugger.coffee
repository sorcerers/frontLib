((location, console) ->
  debugMode = ->
    re = ///(^|\?|&)#{console.debugSwitch}(&|=|$)///
    !!location.search.match(re) or console.debugMode

  console.log ?= ->
  console.debugSwitch ?= "debug"

  console.debugger = ->
    debugger if debugMode()

  holder = (method, fn) -> ->
    return unless debugMode()
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
