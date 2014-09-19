liveCaret = {}

# default
liveCaret.bindTo = 'body'

liveCaret.bindLiveCaret = ->
  eventMap = [
    'form.live-caret input[type=text]'
    'form.live-caret textarea'
    'form.live-caret input[type=email]'
  ].join ', '

  # keep track of our position and pass to our presence
  $(eventMap).bind('keyup click', ->
    form = $(this).parents 'form'
    range = $(this).range()

    Session.set('caretRange',
      form: form.attr 'id'
      name: $(this).attr 'name'
      start: range.start
      end: range.end
      length: range.length
    )
  )

Presence.state = ->
  return {
    route: Router.current() and Router.current().path
    caretRange: Session.get 'caretRange'
  }

createCaret = (id) ->
  rect = document.createElement 'div'

  rect.setAttribute 'data-id', id
  rect.style.position = 'absolute'

  # We must change this in order to define custom colors
  rect.style.backgroundColor = _.first(_.shuffle(['red', 'green', 'orange', 'blue', 'purple']))

  rect.style.height = '22px'
  rect.style.width = '2px'
  rect.style.display = 'none'
  rect.className = 'lcaret'

  $(liveCaret.bindTo).append rect

getCaretCoordinates = (element, position, recalculate) ->
  # mirrored div
  div = document.createElement 'div'
  div.id = 'input-textarea-caret-position-mirror-div'

  document.body.appendChild div

  style = div.style

  # currentStyle for IE < 9
  if window.getComputedStyle isnt undefined
    computed = getComputedStyle(element)
  else
    computed = element.currentStyle

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

setCaretPosition = (id, form, fieldName, coordinates) ->
  field = $("form##{form} [name='#{fieldName}']").get 0
  caret = $(".lcaret[data-id=#{id}]")

  if not field or not caret
    return false

  caret.css(
    display: 'block'
    top: field.offsetTop - field.scrollTop + coordinates.top
    left: field.offsetLeft - field.scrollLeft + coordinates.left
  )

# get the caretRange from the presence, calculate the coordinates
updateCaret = (id, fields) ->
  caretRange = fields.state.caretRange
  coordinates = getCaretCoordinates(
    document.getElementsByName(caretRange.name)[0],
    caretRange.end
  )

  setCaretPosition(id, caretRange.form, caretRange.name, coordinates)

removeCaret = (id) ->
  $(".lcaret[data-id=#{id}]").remove()

Meteor.startup ->
  Deps.autorun ->
    Presences.find(
      'state.route': Router.current() and Router.current().path
    ).observeChanges(
      added: (id, fields) ->
        createCaret(id)

        if fields.state.caretRange is undefined
          return false

        updateCaret(id, fields)

      changed: (id, fields) ->
        updateCaret(id, fields)

      removed: (id) ->
        removeCaret(id)
    )
