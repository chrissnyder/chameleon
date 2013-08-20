$ ->
	$("button").on "click", (e) ->
		e.preventDefault()

		[id, name, value] = $(@).parent().serializeArray()
		accept = $(@).hasClass 'accept'

		obj =
			id: id.value
			name: name.value
			value: value.value
			accept: accept

		request = $.ajax
			type: "POST"
			url: "#{ window.location.pathname }"
			data:	obj

		request.done ->
			console.log "success"
			$(e.currentTarget).parent().html 'Thank you!'

			setTimeout ->
				$(e.currentTarget).animate
					height: 0
					opacity: 0
			, 2000

		request.fail ->
			console.log "fail"

		request.always ->
			console.log "always"
