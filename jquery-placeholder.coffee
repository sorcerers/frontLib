return if $().placeholder?

input = document.createElement 'input'
if 'placeholder' in input
  $.fn.placeholder = ->
  return

$("html").addClass "no-placeholder"
$.fn.placeholder = (options) ->
  @each (index, elem) =>
    return unless ($elem = @eq index).attr "placeholder"
    unless $elem.is "input"
      throw Error 'jquery-placeholder only support input tag now'

    removeData = ->
      return unless $elem?
      $elem.removeData "placeholder_lastValue"
      timer = $elem.data "placeholder_timer"
      clearInterval timer
      $elem.removeData "placeholder_timer"

    dispose = ->
      removeData()
      $elem
        .off(".placeholder")
        .parents(".placeholder-container")
        .find(".placeholder-label")
        .off(".placeholder")
        .remove()

      $elem.unwrap ".placeholder-container"

    return dispose() if options? and not options

    $p = $("<p>", class: "placeholder-container").css
      "position": "relative", "padding": 0, "margin": 0, "overflow": "hidden"
      "display": $elem.css("display"), "float": $elem.css("float")

    $label = $ "<label>",
      for: $elem.attr("id") or ""
      class: "placeholder-label"

    $label.text($elem.attr "placeholder").css
      position: "absolute"
      top: $elem.css("padding-top")
      left: $elem.css("padding-left")
      cursor: "text"
      color: $elem.css("color")
      "font-size": $elem.css("font-size")

    $elem.data "placeholder_timer", setInterval ->
      lastValue = $elem.data "placeholder_lastValue"
      currValue = $elem.val()
      return if currValue is lastValue
      $elem.data "placeholder_lastValue", currValue
      $elem.trigger "change"
    , 100

    events = 'click change keyup'.replace(/(\s|$)+/g, '.placeholder ')
    $elem.wrap($p).before($label).on events, (event) ->
      $label[if $elem.val() then "hide" else "show"]()

    $label.on "click.placeholder mousedown.placeholder", (event) -> $elem.focus()

$ ->
  $('[placeholder]').placeholder()

