
angular.module('ng-extra', [])

.run(-> # angular.clean [[[
  angular.clean = (obj) ->
    angular.fromJson angular.toJson obj
) # ]]]

.config([ # Resource.wrapStaticMethod [[[
  '$provide'

($provide) ->
  $provide.decorator('$resource', [
    '$delegate'

  ($delegate) ->
    (url, paramDefaults, actions) ->
      Resource = $delegate url, paramDefaults, actions
      Resource.wrapStaticMethod = (fnName, fn, deleteInstanceMethod = true) ->
        originalFn = Resource[fnName]
        if deleteInstanceMethod
          delete Resource::["$#{fnName}"]
        Resource[fnName] = fn -> originalFn.apply Resource, arguments

      Resource
  ])
]) # ]]]

.config([ # Resource action normalize [[[
  '$provide'

($provide) ->

  $provide.decorator('$resource', [
    '$delegate'

  ($delegate) ->
    (url, paramDefaults, actions) ->
      Resource = $delegate url, paramDefaults, actions
      angular.forEach actions, (options, method) ->
        return unless options.normalize

        Resource::["$#{method}"] = (params, data, success, error) ->
          if angular.isFunction params
            error = data
            success = params
            params = {}
            data = {}
          else if angular.isFunction data
            error = success
            success = data
            data = {}

          data = angular.copy data
          data.id = @id
          @$resolved = false
          result = Resource[method] params, data, (resp, headers) =>
            angular.copy angular.clean(resp), this
            success? this, headers
          , error

          result.$promise = result.$promise.finally =>
            @$resolved = true
            return

          result.$promise or result

      Resource
  ])

]) # ]]]

.directive('ngBusyButton', -> # [[[
  link: (scope, element, attrs) ->
    originalText = element.text()
    config = scope.$eval(attrs.ngBusyButton) or {}
    isBusy = false

    fn = (cb) ->
      (event) ->
        return if isBusy
        isBusy = true
        promise = scope.$eval cb
        if angular.isDefined(promise) && promise.hasOwnProperty('then')
          promise.then -> isBusy = false

    angular.forEach config.events, (cb, event) ->
      element.on event, fn(cb)

    scope.$watch (-> isBusy), (isBusy) ->
      action = if isBusy then 'add' else 'remove'
      element["#{action}Class"] 'disabled'
      element["#{action}Attr"] 'disabled', 'disabled'
      if angular.isDefined config.busyText
        element.text if isBusy then config.busyText else originalText
) # ]]]

