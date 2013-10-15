AWS = require 'aws-sdk'
express = require 'express'
ECT = require 'ect'
{ flatten, unflatten } = require 'flat'
fs = require 'fs'
jsdom = require 'jsdom'
passport = require 'passport'
GoogleStrategy = require('passport-google').Strategy
mongodb = require 'mongodb'
shortId = require 'shortid'
url = require 'url'
User = require './models/user'
_ = require 'lodash'

# Random bits of setup
port = process.env.PORT || 3002

if process.env.PORT
  MONGO_URL = "mongodb://#{ process.env.MONGO_USER }:#{ process.env.MONGO_PASSWORD }@dharma.mongohq.com:10075/app16834628"
  SESSION_SECRET = process.env.SESSION_SECRET
  RETURN_URL = "http://z8e.herokuapp.com/auth/google/return"
  REALM = "http://z8e.herokuapp.com/"
else
  MONGO_URL = "mongodb://localhost:27017/translations"
  SESSION_SECRET = "bacon-cereal-tempest-1266"
  RETURN_URL = "http://localhost:#{ port }/auth/google/return"
  REALM = "http://localhost:#{ port }/"

ObjectID = mongodb.ObjectID
{ ensureAuthenticated, ensureAdmin, ensureTrusted, parseUpload } = require './lib/functions'

passport.serializeUser (user, done) ->
  done null, user

passport.deserializeUser (obj, done) ->
  done null, obj

app = express()
ectRenderer = ECT
  watch: true
  root: __dirname + '/views'
app.engine '.ect', ectRenderer.render

app.use express.static(__dirname + '/public')
app.use express.bodyParser({uploadDir: __dirname + '/uploads'})
app.use(express.cookieParser())
app.use(express.session({secret: SESSION_SECRET}))
app.use passport.initialize()
app.use passport.session()

passport.use new GoogleStrategy
  returnURL: RETURN_URL
  realm: REALM
  (identifier, profile, done) ->
    process.nextTick ->
      profile.identifier = identifier
      user = new User profile
      app.locals.user = user
      done null, user

##
# MIDDLEWARE STACKS
##
ensureAuthenticatedStack = [ensureAuthenticated]
ensureAdminStack = [ensureAuthenticated, ensureAdmin]
ensureTrustedStack = [ensureAuthenticated, ensureTrusted]


###
# LIBS
###
Languages = require './lib/languages'
Projects = require './lib/projects'
app.locals.projects = Projects

connectionUri = url.parse MONGO_URL
dbName = connectionUri.pathname.replace /^\//, ''

mongodb.Db.connect MONGO_URL, (err, db) ->
  if err then throw err

  console.log 'Connected to Mongo.'

  siteCollection = db.collection 'language_data'
  stringsCollection = db.collection 'language_strings'

  s3 = new AWS.S3
    accessKeyId: process.env.AMAZON_ACCESS_KEY_ID
    secretAccessKey: process.env.AMAZON_SECRET_ACCESS_KEY
    region: 'us-east-1'

  ###
  # ROUTES
  ###
  # Authentication Routes
  app.get(
    '/auth/google'
    passport.authenticate 'google', { failureRedirect: '/login' }
    (req, res) ->
      res.redirect '/'
  )

  app.get(
    '/auth/google/return'
    passport.authenticate 'google', { failureRedirect: '/login' }
    (req, res) ->
      res.redirect '/'
  )

  app.get '/', ensureAuthenticatedStack, (req, res) ->
    res.render 'index.ect', {languages: Languages, projects: Projects}

  app.get '/login', (req, res) ->
    res.render 'login.ect'


  app.get '/project/:project', ensureAuthenticatedStack, (req, res) ->
    { project } = req.params

    opts =
      project: project
      projectName: Projects[project].name
      languages: Languages

    res.render 'site.ect', opts

  app.post '/project/:project', ensureAdminStack, (req, res) ->
    { project } = req.params

    unless req.files["site-file"]
      res.redirect "/project/#{ project }"
      return

    unless rawStrings = parseUpload req.files["site-file"]
      res.send 500
      return

    query =
      project: project

    siteCollection.findOne query, (err, doc) ->
      if doc
        doc.languages.en = rawStrings
      else
        doc = 
          project: project
          languages:
            en: rawStrings

      siteCollection.findAndModify query, { project: 1 }, doc, { safe: true, upsert: true }, (err, objects) ->
        fs.unlink req.files["site-file"].path
        res.redirect "/project/#{ project }"

  app.get '/project/:project/language/:language/translate', (req, res) ->
    { language, project } = req.params

    siteCollection.findOne { project }, (err, projectDoc) ->
      if err
        console.log 'Error', err
        res.send 500
        return

      projectDoc.languages[language] ?= {}
      projectDoc.languages[language] = _.merge projectDoc.languages.en, projectDoc.languages[language]

      opts =
        project: project
        projectName: Projects[project].name
        language: language
        languageName: Languages[language]
        en: flatten projectDoc.languages.en
        strings: flatten projectDoc.languages[language]

      res.render 'translate.ect', opts

  app.post '/project/:project/language/:language/translate', (req, res) ->
    { language, project } = req.params
    { name, value } = req.body

    unless name and value
      res.send 400
      return

    stringObj = {}
    stringObj[name] = value

    obj = {}
    obj["string"] = stringObj
    obj["id"] = shortId.generate()

    stringsCollection.update { project, language }, { $push: { strings: obj } }, { upsert: true, w: 1 }, (err, updatedDoc) ->
      if err
        res.send 400
        return

      res.send 200

  app.get '/project/:project/language/:language/resolve', ensureTrustedStack, (req, res) ->
    { language, project } = req.params

    stringsCollection.findOne { project, language }, (err, doc) ->
      { strings } = doc || []

      opts =
        project: project
        projectName: Projects[project].name
        language: language
        languageName: Languages[language]
        strings: strings

      res.render 'resolver.ect', opts

  app.post '/project/:project/language/:language/resolve', ensureTrustedStack, (req, res) ->
    { language, project } = req.params
    { accept, id, name, value } = req.body

    updateQuery = 
      project: project
      language: language

    updateAction =
      $pull:
        "strings":
          id: id

    stringsCollection.update updateQuery, updateAction, (err, result) ->
      unless accept is "true"
        res.send 200
      else
        obj = {}
        obj["languages.#{ language }.#{ name }"] = value

        updateAction =
          $set: obj

        siteCollection.update { project }, updateAction, (err, doc) ->
          res.send 200

  app.put '/project/:project/language/:language/push', (req, res) ->
    { project, language } = req.params

    siteCollection.findOne { project }, (err, projectDoc) ->
      projectDoc.languages[language] ?= {}
      exportedLanguage = _.merge projectDoc.languages.en, projectDoc.languages[language]

      buffer = new Buffer JSON.stringify(exportedLanguage)
      key = "/translations/#{ language }.json"
      if Projects[project].prefix
        key = "#{ Projects[project].prefix }" + key

      bucket = Projects[project].bucket

      s3.putObject
        Bucket: bucket
        Key: key
        Body: buffer
        ACL: 'public-read'
        ContentType: 'application/json'
        (err, s3Res) ->
          if err
            console.log err
            res.send 400
          else
            res.send 200

  app.put '/project/:project/generate', ensureAdminStack, (req, res) ->
    { project, language } = req.params
    { languages } = req.body

    exportedLanguages = {}
    unless Array.isArray languages
      languages = [languages]

    for languageLocale, languageString of Languages
      exportedLanguages[languageLocale] = languageString if languageString in languages

    siteUrl = Projects[project].bucket_url
    if Projects[project].prefix
      siteUrl = siteUrl + Projects[project].prefix

    jsdom.env siteUrl, (err, window) ->
      if err
        res.send 400
        return

      document = window.document
      # Start fresh each time
      dataEls = document.querySelectorAll "script[id^=define-zooniverse-languages]"
      dataEls[i]?.parentNode.removeChild(dataEls[i]) for i in [0..dataEls.length - 1]

      scriptTag = document.createElement 'script'
      scriptTag.setAttribute 'type', 'text/javascript'
      scriptTag.id = "define-zooniverse-languages"
      scriptTag.innerHTML = "window.DEFINE_ZOONIVERSE_LANGUAGES = #{ JSON.stringify exportedLanguages }"

      firstScript = document.body.querySelector('script')

      if firstScript
        document.body.insertBefore scriptTag, firstScript
      else
        document.head.insertBefore scriptTag, document.head.firstChild

      loadedHtml = "<!DOCTYPE html>\n" + document.documentElement.outerHTML
      buffer = new Buffer loadedHtml

      key = "index.html"
      if Projects[project].prefix
        key = "#{ Projects[project].prefix }/" + key

      bucket = Projects[project].bucket
      s3.putObject
        Bucket: bucket
        Key: key
        ACL: "public-read"
        Body: buffer
        ContentType: "text/html"
        (err, s3Res) ->
          if err then res.send 400; return
          res.send 200


  app.listen port, ->
    console.log "HELLO FROM PORT #{ port }"
