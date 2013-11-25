
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

# html:
#   <button data-busybtn="click dblclick"
#           data-busybtn-text="submiting..."
#           data-busybtn-handler="onclick($event)"
#   >submit</button>
#
# code:
#   $scope.onclick = ->
#     defer = $q.defer()
#     # some code
#     defer.promise
#
.directive('busybtn', -> # [[[
  link: (scope, element, attrs) ->
    originalText = undefined

    isBusy = false

    element.on attrs.busybtn, (event) ->
      return if isBusy
      isBusy = true
      originalText = element.text()
      promise = scope.$eval attrs.busybtnHandler
      if angular.isDefined(promise) and promise.hasOwnProperty('then')
        promise.finally -> isBusy = false

    scope.$watch (-> isBusy), (isBusy) ->
      element["#{if isBusy then 'add' else 'remove'}Class"] 'disabled'
      element["#{if isBusy then 'a' else 'removeA'}ttr"] 'disabled', 'disabled'
      if angular.isDefined attrs.busybtnText
        element.text if isBusy then attrs.busybtnText else originalText
) # ]]]

