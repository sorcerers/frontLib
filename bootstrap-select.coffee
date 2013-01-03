return if $().bootSelect?

$.fn.bootSelect = (options) ->
  throw new Error("element must be select") unless @is "select"

  invalidLink = "javascript:void(0);"
  caret = "<span class='caret'></span>"
  randomName = (prefix) -> prefix + $.now()

  unbindEvent = ($dropdown, $select) ->
    $dropdown.off ".bootSelect"
    $select.off ".bootSelect"

  destroyListItems = ($items) ->
    $items.each (index) ->
      $item = $items.eq index
      $li = $item.data "li"
      $item.removeData "li"
      $li.removeData "option"
      $li.remove()

  bindEvent = ($dropdown, $select) ->
    $dropdown.on "click.bootSelect", ".dropdown-menu li", (event) ->
      $li = $ event.currentTarget
      $dropdown.find(".dropdown-toggle").html $li.find("a").text() + caret
      $select.val $li.data("option").val()
      $select.trigger "change"

    $select.on "change:dom.bootSelect", (event) ->
      $selectedItem = $select.find "option:selected"
      $listItems = generateListItems $select.find "option"
      $dropdown.find(".dropdown-menu").empty().append $listItems
      $dropdown.find(".dropdown-toggle").html $selectedItem.text() + caret

  generateListItems = ($items) ->
    $items.map (index) ->
      $item = $items.eq index
      $li = $("<li>").append $("<a>", href: invalidLink).text $item.text()
      $li.data "option", $item
      $item.data "li", $li
      $li[0]

  generateDropdownMenu = ($items) ->
    $list = $ "<ul>", class: "dropdown-menu"
    $listItems = generateListItems $items
    $list.append $listItem for $listItem in $listItems

  if options is false
    # dispose
    @show().each (index, elem) =>
      $this = @eq index
      $items = $this.find "option"
      $dropdown = $this.data("dropdown").removeData "select"
      $this.removeData("dropdown").removeAttr "data-select"

      unbindEvent $dropdown, $this
      destroyListItems $items
      $dropdown.remove()

  else

    @hide().each (index, elem) =>
      $this = @eq index
      $items = $this.find "option"
      selectName = randomName "select"

      $dropdown = $ "<div>",
        class: "dropdown #{$this.data "bs-class"}"
        "data-select": selectName
      .data "select", $this

      $this.attr("data-select", selectName).data "dropdown", $dropdown

      $toggler = $ "<button>",
        class: "btn dropdown-toggle"
        "data-toggle": "dropdown"
      .html $this.find(":selected").text() + caret

      $dropdownMenu = generateDropdownMenu $items
      $dropdown.append($toggler).append $dropdownMenu
      $this.before $dropdown
      $toggler.dropdown()

      bindEvent $dropdown, $this
