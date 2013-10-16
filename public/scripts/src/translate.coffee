GOOGLE_API_KEY = 'AIzaSyCiX8byicCP61gdCd9nYIzhzbHLNmw63pc'

$ ->
	$('button[name="google-translate"]').on 'click', ({ currentTarget }) ->
		target = $(currentTarget)
		translateUri = "https://www.googleapis.com/language/translate/v2?key=#{ GOOGLE_API_KEY }&source=en&target=#{ target.data('language-code') }&q=#{ target.data('translate-string') }"

		translateRequest = $.get encodeURI translateUri
		translateRequest.done (result) ->
			if 'data' of result
				translatedString = result.data.translations[0].translatedText
				associatedTextArea = target.parent().children('label').children('textarea')
				associatedTextArea.val(translatedString)

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
