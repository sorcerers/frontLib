
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

