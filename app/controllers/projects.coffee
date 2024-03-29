AWS = require 'aws-sdk'
coffee = require 'coffee-script'
fs = require 'fs'
jsdom = require 'jsdom'
path = require 'path'
User = require '../models/user'

parseUpload = (fileObject) ->
  try
    switch path.extname fileObject.name
      when ".json"
        rawStrings = JSON.parse fs.readFileSync fileObject.path
      when ".coffee"
        rawFile = fs.readFileSync fileObject.path
        rawStrings = coffee.eval rawFile.toString()
      else
        throw new Error 'File extension not supported.'
  catch e
    console.log 'e', e
    return false

  rawStrings

module.exports = ({ app, db }) ->
  { ProjectsList, LanguagesList } = app.locals

  get: (req, res) ->
    { project } = req.params
    
    opts =
      project: project

    res.render 'site.ect', opts

  # Injects a raw language file into a project.
  bootstrap: (req, res) ->
    { project } = req.params
    { language } = req.body

    unless req.files["site-file"]
      res.redirect "/project/#{ project }"
      return

    unless rawStrings = parseUpload req.files["site-file"]
      res.send 500
      return

    siteCollection = db.collection 'language_data'

    query =
      project: project

    siteCollection.findOne query, (err, doc) ->
      if doc
        doc.languages[language] = rawStrings
      else
        doc = 
          project: project
        doc.languages = {}
        doc.languages[language] = rawStrings

      siteCollection.findAndModify query, { project: 1 }, doc, { safe: true, upsert: true }, (err, objects) ->
        fs.unlink req.files["site-file"].path
        res.redirect "/project/#{ project }"

  generateManifest: (req, res) ->
    { project, language } = req.params
    { languages } = req.body

    exportedLanguages = {}
    unless Array.isArray languages
      languages = [languages]

    for languageLocale, languageString of LanguagesList
      exportedLanguages[languageLocale] = languageString if languageString in languages

    siteUrl = ProjectsList[project].bucket_url
    if ProjectsList[project].prefix
      siteUrl = siteUrl + ProjectsList[project].prefix

    jsdom.env siteUrl, (err, { document }) ->
      if err
        res.send 400
        return

      # Start fresh each time
      dataEls = document.querySelectorAll "script[id^=define-zooniverse-languages]"
      dataEls[i]?.parentNode.removeChild(dataEls[i]) for i in [0..dataEls.length - 1]

      scriptTag = document.createElement 'script'
      scriptTag.setAttribute 'type', 'text/javascript'
      scriptTag.id = "define-zooniverse-languages"
      scriptTag.innerHTML = "window.AVAILABLE_TRANSLATIONS = #{ JSON.stringify exportedLanguages }"

      firstScript = document.body.querySelector('script')

      if firstScript
        document.body.insertBefore scriptTag, firstScript
      else
        document.head.insertBefore scriptTag, document.head.firstChild

      loadedHtml = "<!DOCTYPE html>\n" + document.documentElement.outerHTML
      buffer = new Buffer loadedHtml

      key = "index.html"
      if ProjectsList[project].prefix
        key = "#{ Projects[project].prefix }/" + key

      bucket = ProjectsList[project].bucket
      accessKeyId = ProjectsList[project].key || process.env.AMAZON_ACCESS_KEY_ID
      secretAccessKey = ProjectsList[project].secret || process.env.AMAZON_SECRET_ACCESS_KEY

      s3 = new AWS.S3
        accessKeyId: accessKeyId
        secretAccessKey: secretAccessKey

      s3.putObject
        Bucket: bucket
        Key: key
        Body: buffer
        ACL: "public-read"
        ContentType: "text/html"
        (err, s3Res) ->
          if err
            console.log err
            res.send 400
            return

          res.send 200

