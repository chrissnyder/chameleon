$ ->
	$("form").on "submit", (e) ->
		e.preventDefault()
		formDataArray = $(@).serializeArray()

		request = $.ajax
			type: "POST"
			url: "#{ window.location.pathname }"
			data:	formDataArray[0]

		request.done ->
			console.log "success"
			$(e.currentTarget).html 'Thank you!'

			setTimeout ->
				$(e.currentTarget).animate
					height: 0
					opacity: 0
			, 2000

		request.fail ->
			console.log "fail"

		request.always ->
			console.log "always"
