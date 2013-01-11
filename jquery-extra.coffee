(($) ->
  ajaxActionFactroy = (type, postLike) ->
    (url, data, success, dataType, contentType) ->
      if jQuery.isFunction data
        dataType or= success
        success = data
        data = undefined

      options = {url, type, dataType, data, success}
      if postLike
        if contentType
          options["contentType"] = contentType
        else
          options["contentType"] = "application/json"
          options["processData"] = false

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
