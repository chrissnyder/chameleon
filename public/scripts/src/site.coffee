$.fn.indicate = (resultBool) ->
	color = if resultBool then '#090' else '#900'

	@css 'border-color', color
	setTimeout =>
		@css 'border-color', 'transparent'
	, 1600

$ ->
	$('a.push').on 'click', (e) ->
		e.preventDefault()

		target = $(e.currentTarget)
		listItem = target.parent()

		request = $.ajax
			type: 'PUT'
			url: "#{ window.location.pathname }/language/#{ target.data('language') }/push"

		request.done ->
			listItem.indicate true

		request.fail ->
			listItem.indicate false

	$('form.generate').on 'submit', (e) ->
		e.preventDefault()

		request = $.ajax
			type: 'PUT'
			url: "#{ window.location.pathname }/generate"
			data: $(@).serializeArray()

		request.done ->
			console.log 'generate success'

		request.fail ->
			console.log 'generate fail'
