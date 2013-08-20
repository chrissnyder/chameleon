exports.ensureAuthenticated = (req, res, next) ->
		console.log 'checking auth'
		if req.isAuthenticated()
			console.log 'authed'
			return next()

		res.redirect '/login'