liveCaret = {}

# default
liveCaret.bindTo = 'body'

liveCaret.bindLiveCaret = ->
  eventMap = [
    'form.live-caret input[type=email]'
    'form.live-caret input[type=text]'
    'form.live-caret textarea'
  ].join ', '

  # keep track of our position and pass to our presence
  $(eventMap).bind('keyup click', ->
    $self = $(this)
    range = $(this).range()

    Session.set('caretRange',
      form: $self.parents('form').attr 'id'
      name: $self.attr 'name'
      start: range.start
      end: range.end
      length: range.length
    )
  )

Presence.state = ->
  return {
    caretRange: Session.get 'caretRange'
    href: location.href
    route: Router.current() and Router.current().path
  }

getStyle = (element) ->
  if window.getComputedStyle
    return window.getComputedStyle element
  else
    return element.currentStyle

createCaret = (id) ->
  box = $(liveCaret.bindTo).get 0

  if not box then return false

  getColor = ->
    presence = Presences.findOne _id: id
    user = Meteor.users.findOne _id: presence and presence.userId
    return user and user.profile.color or share.getRandomColor()

  caret = $("<div id='caret_#{id}'></div>")
  caret.css(
    background: getColor()
    position: 'absolute'
    display: 'none'
    height: getStyle(box).fontSize
    width: '2px'
    zIndex: 1
  )

  box.appendChild caret.get(0)

getCaretCoordinates = (element, position, recalculate) ->
  # mirrored div
  div = document.createElement 'div'
  div.id = 'input-textarea-caret-position-mirror-div'

  document.body.appendChild div

  style = div.style

  # currentStyle for IE < 9
  computed = getStyle(element)

  # default textarea styles
  style.whiteSpace = 'pre-wrap'

  if element.nodeName isnt 'INPUT'
    style.wordWrap = 'break-word'  # only for textarea-s

  # position off-screen
  style.position = 'absolute'  # required to return coordinates properly
  style.visibility = 'hidden'  # not 'display: none' because we want rendering

  properties = [
    'direction'  # RTL support
    'boxSizing'
    'width'  # on Chrome and IE, exclude the scrollbar, so the mirror div wraps exactly as the textarea does
    'height'
    'overflowX'
    'overflowY'  # copy the scrollbar for IE

    'borderTopWidth'
    'borderRightWidth'
    'borderBottomWidth'
    'borderLeftWidth'

    'paddingTop'
    'paddingRight'
    'paddingBottom'
    'paddingLeft'

    # https://developer.mozilla.org/en-US/docs/Web/CSS/font
    'fontStyle'
    'fontVariant'
    'fontWeight'
    'fontStretch'
    'fontSize'
    'fontSizeAdjust'
    'lineHeight'
    'fontFamily'

    'textAlign'
    'textTransform'
    'textIndent'
    'textDecoration'  # might not make a difference, but better be safe

    'letterSpacing'
    'wordSpacing'
  ].forEach (property) ->
    style[property] = computed[property]

  if window.mozInnerScreenX isnt null
    # Firefox adds 2 pixels to the padding - https://bugzilla.mozilla.org/show_bug.cgi?id=753662
    style.width = parseInt(computed.width, 10) - 2 + 'px'

    # Firefox lies about the overflow property for textareas: https://bugzilla.mozilla.org/show_bug.cgi?id=984275
    if element.scrollHeight > parseInt(computed.height, 10)
      style.overflowY = 'scroll'
  else
    # for Chrome to not render a scrollbar; IE keeps overflowY = 'scroll'
    style.overflow = 'hidden'

  div.textContent = element.value.substring(0, position)

  # the second special handling for input type="text" vs textarea:
  # spaces need to be replaced with non-breaking spaces - http://stackoverflow.com/a/13402035/1269037
  if element.nodeName is 'INPUT'
    div.textContent = div.textContent.replace(/\s/g, "\u00a0")

  span = document.createElement 'span'

  # Wrapping must be replicated *exactly*, including when a long word gets
  # onto the next line, with whitespace at the end of the line before (#7).
  # The  *only* reliable way to do that is to copy the *entire* rest of the
  # textarea's content into the <span> created at the caret position.
  # for inputs, just '.' would be enough, but why bother?
  # || because a completely empty faux span doesn't render at all
  span.textContent = element.value.substring(position) or '.'
  div.appendChild span

  coordinates =
    top: span.offsetTop + parseInt(computed['borderTopWidth'], 10)
    left: span.offsetLeft + parseInt(computed['borderLeftWidth'], 10)

  document.body.removeChild div

  return coordinates

# get the caretRange from the presence, calculate the coordinates
updateCaret = (id, fields) ->
  range = fields.state and fields.state.caretRange

  if not range then return false

  field = $("form##{range.form} [name='#{range.name}']").get 0

  if not field then return false

  coordinates = getCaretCoordinates(field, range.end)

  $("#caret_#{id}").css
    display: 'block'
    top: field.offsetTop - field.scrollTop + coordinates.top
    left: field.offsetLeft - field.scrollLeft + coordinates.left

removeCaret = (id) ->
  $("#caret_#{id}").remove()

Meteor.startup ->
  Deps.autorun ->
    Presences.find(
      'state.route': Router.current() and Router.current().path
    ).observeChanges(
        added: (id, fields) ->
          createCaret(id)
          updateCaret(id, fields)

        changed: (id, fields) ->
          updateCaret(id, fields)

        removed: (id) ->
          removeCaret(id)
      )
