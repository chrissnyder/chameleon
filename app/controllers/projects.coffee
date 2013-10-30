jsdom = require 'jsdom'
{ parseUpload } = require '../lib/functions'
User = require '../models/user'

module.exports = ({ app, db }) ->
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

    for languageLocale, languageString of Languages
      exportedLanguages[languageLocale] = languageString if languageString in languages

    siteUrl = ProjectsList[project].bucket_url
    if ProjectsList[project].prefix
      siteUrl = siteUrl + ProjectsList[project].prefix

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
      if ProjectsList[project].prefix
        key = "#{ Projects[project].prefix }/" + key

      bucket = ProjectsList[project].bucket
      s3.putObject
        Bucket: bucket
        Key: key
        ACL: "public-read"
        Body: buffer
        ContentType: "text/html"
        (err, s3Res) ->
          if err then res.send 400; return
          res.send 200

