return if $().placeholder?

$.fn.placeholder = (options) ->
  return if Modernizr.input.placeholder is true

  $("html").addClass "no-placeholder"
  @each (index, elem) =>
    return if elem.tagName.toLowerCase() isnt "input"
    return unless ($elem = @eq index).attr "placeholder"

    removeData = ->
      return unless $elem?
      $elem.removeData "placeholder_lastValue"
      timer = $elem.data "placeholder_timer"
      clearInterval timer
      $elem.removeData "placeholder_timer"

    if options? and not options
      removeData()

      $container = $elem
        .off(".placeholder")
        .parents ".placeholder-container"

      $container
        .find(".placeholder")
        .off ".placeholder"

      return

    $p = $("<p>", class: "placeholder-container").css
      "position": "relative", "padding": 0, "margin": 0, "overflow": "hidden"
      "display": $elem.css("display"), "float": $elem.css("float")

    $label = $ "<label>", for: $elem.attr("id") or "", class: "placeholder"

    $label.text($elem.attr "placeholder").css
      position: "absolute"
      top: $elem.css("padding-top")
      left: $elem.css("padding-left")
      color: $elem.css("color")
      "font-size": $elem.css("font-size")

    $elem.data "placeholder_timer", setInterval ->
      lastValue = $elem.data "placeholder_lastValue"
      currValue = $elem.val()
      return if currValue is lastValue
      $elem.data "placeholder_lastValue", currValue
      $elem.trigger "change"
    , 100

    events = ("#{event}.placeholder" for event in ["click", "change", "keyup"]).join " "

    $elem.wrap($p).before($label).on events, (event) ->
      $label[`$elem.val()? "hide": "show"`]()

    $label.on "mousedown.placeholder", (event) -> $elem.focus()
