((location, console) ->
  debugMode = ->
    re = ///(^|\?|&)#{console.debugSwitch}(&|=|$)///
    !!location.search.match(re) or console.debugMode

  console.log ?= ->
  console.debugSwitch ?= "debug"

  console.debugger = ->
    debugger if debugMode()

  holder = (method, fn) ->
    # typeof console.log is object in IE9
    #  http://stackoverflow.com/questions/5538972/console-log-apply-not-working-in-ie9#answer-5539378
    if fn and typeof fn is "object"
      fn = Function::bind.call fn, console
    ->
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

  while method = methods.shift()
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
