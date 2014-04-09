class ProgressBar

  @show: ->
    if $("#progress").length is 0
      $("body").append($("<div><dt/><dd/></div>").attr("id", "progress"))
      $("#progress").width((50 + Math.random() * 30) + "%")

  @hide: ->
    $("#progress").width("101%").delay(200).fadeOut 400, ->
      $(@).remove()

window.ProgressBar = ProgressBar

$(document).ajaxStart ->
  ProgressBar.show()

$(document).ajaxComplete ->
  ProgressBar.hide()
