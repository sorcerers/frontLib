Handlebars.registerHelper "debugger", -> debugger
Handlebars.registerHelper "linkInvalid", -> "javascript:void(0);"
Handlebars.registerHelper "blockComment", -> ""

Handlebars.registerHelper "multiplyBy", (count, multiplyBy) -> (parseInt(count, 10) or 0) * multiplyBy
Handlebars.registerHelper "quote", (attrName) -> this[attrName]

# collection
Handlebars.registerHelper "withBeforeThan", (array, count, options) ->
  (options.fn item for item in array.slice 0, count).join ""

Handlebars.registerHelper "withAfterThan", (array, count, options) ->
  (options.fn item for item in array.slice count).join ""

Handlebars.registerHelper "withIndex", (array, indexs..., options) ->
  result = ""
  for i in [0...array.length]
    method = if indexs.length and i in indexs then "fn" else "inverse"
    result += options[method] array[i]
  result

Handlebars.registerHelper "isEmpty", (obj, options) ->
  method = if _(obj).isEmpty() then "fn" else "inverse"
  options[method] this

Handlebars.registerHelper "lengthGt", (array, length, options) ->
  method = if array.length > length then "fn" else "inverse"
  options[method] this
Handlebars.registerHelper "lengthGte", (array, length, options) ->
  method = if array.length >= length then "fn" else "inverse"
  options[method] this
Handlebars.registerHelper "lengthLt", (array, length, options) ->
  method = if array.length < length then "fn" else "inverse"
  options[method] this
Handlebars.registerHelper "lengthLte", (array, length, options) ->
  method = if array.length <= length then "fn" else "inverse"
  options[method] this

Handlebars.registerHelper "withCount", (array, start, count, options) ->
  [options, count, start] = [count, start, 0] unless options
  (options.fn item for item in array[start...start + count]).join ""

Handlebars.registerHelper "if", (contexts..., options) ->
  options = context: options, args: [this]
  handlerMap = true: "fn", false: "inverse"
  _(contexts).chain()
    .batchIf([this])
    .disjunctor(handlerMap, options)
    .value()

Handlebars.registerHelper "unless", (contexts..., options) ->
  Handlebars.helpers.if context..., _(options).swap ["fn", "inverse"]

# string
Handlebars.registerHelper "startWith", (value, startStr, options) ->
  result = if _.isFunction(value) then value.call(this) else value
  resultStartStr = result.slice 0, startStr.length
  method = if resultStartStr is startStr then "fn" else "inverse"
  options[method] this

Handlebars.registerHelper "textPlaceholder", (str, placeholder) ->
  testStr = str.replace /\s*/g, ""
  if testStr then new Handlebars.SafeString(str) else placeholder

Handlebars.registerHelper 'truncate', (str, length, omission) ->
  omission = "" unless omission?
  str = str.toString()
  if str.length > length
    str.substring(0, length - omission.length) + omission
  else
    str

# object
Handlebars.registerHelper "has", (obj, elem, options) ->
  result = if not obj? or not elem? then false else _(elem).in obj
  options[if result then "fn" else "inverse"] this


#  {{#partial "show-person" sortby_create_time}}
#  <div class="reply">
#    <div class="reply-info">
#      {{#owner}}{{name}}{{/owner}}
#      <p>{{formatTime create_time}}{{#if sortby_create_time}}发布{{else}}讨论{{/if}}</p>
#    </div>
#    <img class="avatar" src="{{#owner}}{{image}}{{/owner}}" alt="" width="40px" height="40px">
#  </div>
#  {{/partial}}
#
#  {{#if sortby_create_time}}
#    {{#first_floor}}
#      {{{partial "show-person" "sortby_create_time" ../../../sortby_create_time}}}
#    {{/first_floor}}
#  {{else}}
#    {{#last_update}}
#      {{{partial "show-person" "sortby_create_time" ../../../sortby_create_time}}}
#    {{/last_update}}
#  {{/if}}
partial = {}
Handlebars.registerHelper "partial", (name, args..., options) ->
  if options.fn?
    partial[name] = options.fn
    ""
  else if partial[name]
    data = _.clone this
    if args.length
      for i in _.range(0, args.length, 2)
        data[args[i]] = args[i + 1]
    partial[name] data
  else
    console?.log? "partial #{name} not exist"
    ""

# <p class="description">{{{exec "truncate" "(" "textPlaceholder" content "&nbsp;" ")" 100 "..."}}}</p>
exec = (args..., options) ->
  helperName = args.shift()
  if helperName not in _(Handlebars.helpers).keys()
    return Handlebars.helpers.helperMissing helperName

  subExecStart = args.indexOf("(")
  subExecEnd = args.lastIndexOf(")")
  if !!~subExecStart and !!~subExecEnd
    subExec = args.splice(subExecStart, subExecEnd - subExecStart + 1)
    result = exec subExec.slice(1, -1)..., options
    args.splice(subExecStart, 0, result)
  Handlebars.helpers[helperName] args..., options

Handlebars.registerHelper "exec", exec
