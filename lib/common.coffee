share.getRandomColor = ->
  hex = (Math.random() * 0xFFFFFF << 0).toString 16
  hex += '9' while hex.length < 6
  return "##{hex}"
