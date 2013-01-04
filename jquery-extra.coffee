(($) ->
  ajaxActionFactroy = (method) ->
    (url, data, callback, type) ->
      if jQuery.isFunction data
        type or= callback
        callback = data
        data = undefined

      jQuery.ajax
        type: method
        url: url
        data: data
        success: callback
        dataType: type

  for method in ["pub", "delete"]
    $[method] = ajaxActionFactroy method

  $.fn.include = ($elem) ->
    $elem = $($elem) unless $elem instanceof $
    return true if @is $elem
    return true if $.contains this[0], $elem[0]
    false

) jQuery
