(($) ->
  ajaxActionFactroy = (method, postLike) ->
    (url, data, callback, type) ->
      if jQuery.isFunction data
        type or= callback
        callback = data
        data = undefined

      options =
        type: method
        url: url
        data: data
        success: callback

      if postLike and not type
        options["type"] = "application/json"
        options["processData"] = false
      else if type
        options["type"] = type if type

      jQuery.ajax options

  for method in ["get", "head", "delete"]
    $[method] = ajaxActionFactroy method

  for method in ["post", "put", "patch", "option"]
    $[method] = ajaxActionFactroy method, true

  $.fn.include = ($elem) ->
    return false unless @length
    $elem = $($elem) unless $elem instanceof $
    return true if @is $elem
    return true if $.contains this[0], $elem[0]
    false

) jQuery
