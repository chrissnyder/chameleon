$ ->
	$('a.push').on 'click', (e) ->
		e.preventDefault()

		target = $(e.currentTarget)

		request = $.ajax
			type: 'PUT'
			url: "#{ window.location.pathname }/language/#{ target.data('language') }/push"

		request.done ->
			console.log 'push success'

		request.fail ->
			console.log 'push fail'

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
