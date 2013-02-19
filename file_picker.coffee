###
  requirements:
    jQuery: http://jquery.com/
    underscore: http://underscorejs.org/
    fineuploader: http://fineuploader.com/
###

# Override [[[
qq.UploadHandlerForm::__createInput = (name, value) ->
  input = document.createElement "input"
  input.name = name
  input.value = value
  input

qq.UploadHandlerForm::_createForm = (iframe, params) ->
  formHtml = '<form method="POST" enctype="multipart/form-data"></form>'
  form = qq.toElement formHtml
  queryString = qq.obj2url params, @_options.endpoint

  for key, value of @_options.formData
    form.appendChild @__createInput key, value

  form.setAttribute 'action', queryString
  form.setAttribute 'target', iframe.name
  form.style.display = 'none'
  document.body.appendChild form
  form
# ]]]

$.support.xhrprogress = File? and FormData? and (new XMLHttpRequest).upload?
$.support.inputMultiple = `"multiple" in document.createElement("input")`

###
params:
  selector: {jQuery, jQuery Selector, HTMLElement} button element
  options:
    autoSubmit: {Boolean}
    multiple: {Boolean}
    mimeType: {Array}
    action: {String}
    data: {Hash}
events:
  filepicker.complete
  filepicker.failure
  filepicker.success
  filepicker.progress
  filepicker.upload
  filepicker.change
###
class FilePicker # [[[
  constructor: (selector, options) ->
    if _.isString(selector) or _.isElement(selector)
      $el = $ selector
    else if selector instanceof $
      $el = selector
    else
      $el = []
    unless $el.length
      throw new Error "not support selector"

    name = "filePicker"
    finalOptions = $.extend {
      name
      mimeType: ("image/#{ext}" for ext in ["png", "jpg", "jpeg", "gif"])
      autoSubmit: false
      multiple: false
    }, options

    @el = $el[0]
    @$el = $el
    @_submitData = {}
    @_uploading = false
    @expando = finalOptions.name + $.now()
    @options = @_optionsAdapter finalOptions
    @_init @options

  clearData: -> @_submitData = null
  setData: (data) -> @_submitData = $.extend @_submitData or {}, data
  fileElem: -> @uploadButton?.getInput?()
  $fileElem: -> $ @fileElem()
  fileName: -> @fileElem()?.value.replace /.*(\/|\\)/, ""
  emptyFile: -> @uploadButton?.reset?()
  disableButton: => @$fileElem().hide().css "z-index": -1
  activeButton: => @$fileElem().show().css "z-index": 3

  submit: (callback) ->
    if @options.multiple
      extraData = files: @fileElem().files
      @constructor.sendMulit $.extend @options, {data: @_submitData}, extraData
    else
      extraData = fileInput: @fileElem()
      @constructor.send $.extend @options, {data: @_submitData}, extraData

  remove: (options) ->
    @clearData()
    @emptyFile()
    @$el.off ".#{@expando}"
    @$fileElem().remove()
    delete @uploadButton

  _init: (options) ->
    @_initButton options
    @$el.data "filePicker", this
    @$fileElem().data "filePicker", this

  _initButton: (options) ->
    @remove()
    @uploadButton = new qq.UploadButton options
    @$fileElem().addClass("filePickers").hide().css left: 0, bottom: 0
    @$el.on "mouseover.#{@expando}", (event) =>
      if @_uploading then @disableButton() else @activeButton()
    .on("mouseout.#{@expando}", @disableButton)
    #.on "dragover.#{@expando}", @_disableButton

  _optionsAdapter: (options) ->
    options = @_wrapOptionHandler _.clone options
    options.url = options.action
    options.element = @el
    options.acceptFiles = options.mimeType
    @setData options.data
    delete options.ext
    delete options.data
    delete options.action
    unless $.support.inputMultiple
      delete options.multiple
    options

  _wrapOptionHandler: (options) -> # [[[
    {onChange, onUpload, onProgress, onSuccess, onFailure, onComplete} = options
    $.extend options,
      onComplete: (fileName, data) =>
        @_uploading = false
        @emptyFile()
        onComplete?.apply @el, [fileName, data]

      onFailure: (data) =>
        fileName = @fileName()
        @$el.trigger "filepicker.failure", [fileName, data]
        @$el.trigger "filepicker.complete", [fileName, data]
        onFailure?.apply @el, [fileName, data]
        @options.onComplete fileName, data

      onSuccess: (data) =>
        # TODO: 多张上传的话文件名就不能是这样了
        fileName = @fileName()
        return @options.onFailure data if data?.error?
        @$el.trigger "filepicker.success", [fileName, data]
        @$el.trigger "filepicker.complete", [fileName, data]
        onSuccess?.apply @el, [fileName, data]
        @options.onComplete fileName, data

      onProgress: (data) =>
        fileName = @fileName()
        @$el.trigger "filepicker.progress", [fileName, data]
        onProgress?.apply @el, [fileName, data]

      onUpload: =>
        fileName = @fileName()
        @$el.trigger "filepicker.upload", [fileName]
        result = onUpload?.apply @el, [fileName]
        @_uploading = true if result isnt false
        result

      onChange: (input) =>
        @el.files = @fileElem().files if $.support.xhrprogress
        @$el.trigger "filepicker.change", [@fileName(), @el.files]
        result = onChange?.call @el, fileName, @el.files
        return false if result is false
        @submit() if @options.autoSubmit
  # ]]]
# ]]]

# send [[[
send = (options) =>
  sendMethod = if $.support.xhrprogress then sendFormData else sendForm
  sendMethod? options

sendMulit = (options) ->
  options = _.clone options
  {files, onProgress, onFailure, onSuccess} = options
  delete options.files

  files = _(files).toArray()
  filesDatas = []

  fileCount = files.length
  total = if $.support.xhrprogress
    _(file.size for file in files).reduce (result, number) ->
      result + number
  else
    files.length

  options.onProgress = ({loaded}) ->
    onProgress? {loaded, total}

  options.onSuccess = (resp) ->
    filesDatas.push resp
    fileCount--
    return if fileCount
    onSuccess? filesDatas

  while files.length
    options.file = files.shift()
    send options

xhrUpload = (options) ->
  {url, headers, data, onUpload, onProgress, onSuccess, onFailure} = options
  xhrGenerator = ->
    xhr = $.ajaxSettings.xhr()
    xhr.upload.onprogress = (event) ->
      {lengthComputable, position, loaded, totalSize, total} = event
      return unless lengthComputable
      loaded = position or loaded
      total = totalSize or total
      console.log loaded, total
      onProgress? {loaded, total}
    xhr

  uploadResult = onUpload?()
  return if uploadResult? and uploadResult is false

  $.ajax
    url: url
    xhr: xhrGenerator
    data: data
    type: "POST"
    cache: false
    contentType: false
    processData: false
    headers:
      $.extend
        "Accept": "application/json"
        "Cache-Control": "no-cache"
      , headers
  .success (data) ->
    onSuccess? data
  .error (jqXHR) ->
    onFailure? jqXHR.responseText

shimFormData = (params, options, callback) =>
  shimFormDataObj = new ShimFormData params
  shimFormDataObj.build (boundary, data) ->
    options.data = data
    options.headers =
      "Content-Type": "multipart/form-data; boundary=#{boundary}"
    callback? options

formData = (params, options, callback) =>
  formDataObj = new FormData()
  formDataObj.append(k, v) for k, v of params
  options.data = formDataObj
  callback? options

sendFormData = (options) =>
  {fileInput, file, params} = options
  delete options.file
  delete options.fileInput
  delete options.params
  file or= fileInput.files[0]
  params ?= {}
  params["image"] = file
  params["filename"] = file.name
  formDataFunc = if ShimFormData? then shimFormData else formData
  formDataFunc params, options, xhrUpload

sendForm = (options) ->
  {url, fileInput, params, onUpload, onProgress, onSuccess, onFailure} = options
  callbackName = "callback#{$.now()}"
  success = false

  defaultFormData = {callback: callbackName}
  uploadHandlerForm = new qq.UploadHandlerForm
    endpoint: url
    inputName: "image"
    formData: $.extend defaultFormData, params
    onUpload: (args...) -> onUpload? args...
    onProgress: (id, fileName, loaded, total) -> onProgress? {loaded, total}
    onComplete: (id, fileName, response) ->
      setTimeout ->
        return if success
        onFailure? responseText: '{"error": "server error"}'
      , 1000
    onCancel: (id, fileName) ->
      onFailure? responseText: '{"error": "server error"}'

  fileId = uploadHandlerForm.add fileInput
  window[callbackName] = (data) ->
    success = true
    delete window[callbackName]
    onSuccess? data

  uploadHandlerForm.upload fileId

classMethods = {send, sendMulit, sendForm, sendFormData}
# ]]]

window.qq ?= {}
qq.FilePicker = $.extend FilePicker, classMethods
