#React = require 'react'

injectProps = require('./react/injectProps').default
ComponentsIndex = require('./react/pages/ComponentsIndex')
NewComponent = require('./react/pages/NewComponent').default
NewComponentButton = require './react/components/NewComponentButton'
AddComponentConfigurationButton = require './react/components/AddComponentConfigurationButton'


NewComponentFormPage = require './react/pages/new-component-form/NewComponentForm'
ComponentDetail = require './react/pages/component-detail/ComponentDetail'

ComponentReloaderButton = require './react/components/ComponentsReloaderButton'
ComponentsStore = require './stores/ComponentsStore'
InstalledComponentsActionsCreators = require './InstalledComponentsActionCreators'
ComponentsActionCreators = require './ComponentsActionCreators'


exDbRoutes = require '../ex-db/exDbRoutes'
exGdriveGoogleRoutes = require '../ex-google-drive/exGdriveRoutes'
exGanalRoutes = require '../ex-google-analytics/exGanalRoutes'
appGeneeaRoutes = require '../app-geneea/appGeneeaRoutes'
goodDataWriterRoutes = require '../gooddata-writer/routes'
dropoxExtractorRoutes = require('../ex-dropbox/routes').default
dropoxWriterRoutes = require '../wr-dropbox/routes'
createDbWriterRoutes = require '../wr-db/routes'
createGenericDetailRoute = require './createGenericDetailRoute'
googleDriveWriterRoutes = require '../wr-google-drive/wrGdriveRoutes'
tdeRoutes = require '../tde-exporter/tdeRoutes'
adformRoutes = require('../ex-adform/routes').default
geneeaGeneralRoutes = require('../app-geneea-nlp-analysis/routes').default
customScienceRoutes = require('../custom-science/Routes').default

extractor = injectProps(type: 'extractor')
writer = injectProps(type: 'writer')
application = injectProps(type: 'application')


routes =

  applications:
    name: 'applications'
    title: 'Applications'
    requireData: ->
      InstalledComponentsActionsCreators.loadComponents()
    defaultRouteHandler: application(ComponentsIndex)
    headerButtonsHandler: injectProps(
      text: 'New Application'
      to: 'new-application'
      type: 'application'
    )(NewComponentButton)
    reloaderHandler: ComponentReloaderButton
    childRoutes: [
      name: 'new-application'
      title: 'New Application'
      defaultRouteHandler: application(NewComponent)
    ,
      createGenericDetailRoute 'application'
    ,
      appGeneeaRoutes.sentimentAnalysis
    ,
      appGeneeaRoutes.topicDetection
    ,
      appGeneeaRoutes.lemmatization
    ,
      appGeneeaRoutes.correction
    ,
      appGeneeaRoutes.languageDetection
    ,
      appGeneeaRoutes.entityRecognition
    ,
      geneeaGeneralRoutes
    ,
      customScienceRoutes
    ]

  extractors:
    name: 'extractors'
    title: 'Extractors'
    requireData: ->
      InstalledComponentsActionsCreators.loadComponents()
    defaultRouteHandler: extractor(ComponentsIndex)
    headerButtonsHandler: injectProps(text: 'New Extractor', to: 'new-extractor', type: 'extractor')(NewComponentButton)
    reloaderHandler: ComponentReloaderButton
    childRoutes: [
      name: 'new-extractor'
      title: 'New Extractor'
      defaultRouteHandler: extractor(NewComponent)
    ,
      createGenericDetailRoute 'extractor'
    ,
      exDbRoutes
    ,
      exGdriveGoogleRoutes
    ,
      exGanalRoutes
    ,
      adformRoutes
    ,
      dropoxExtractorRoutes
    ,
      createGenericDetailRoute 'extractor'
    ]

  writers:
    name: 'writers'
    title: 'Writers'
    requireData: ->
      InstalledComponentsActionsCreators.loadComponents()
    defaultRouteHandler: writer(ComponentsIndex)
    headerButtonsHandler: injectProps(text: 'New Writer', to: 'new-writer', type: 'writer')(NewComponentButton)
    reloaderHandler: ComponentReloaderButton
    childRoutes: [
      name: 'new-writer'
      title: 'New Writer'
      defaultRouteHandler: writer(NewComponent)
    ,
      createGenericDetailRoute 'writer'
    ,
      goodDataWriterRoutes
    ,
      dropoxWriterRoutes
    ,
      tdeRoutes
    ,
      googleDriveWriterRoutes
    ,
      createDbWriterRoutes('wr-db', 'mysql', true)
    ,
      createDbWriterRoutes('wr-db-mysql', 'mysql', true)
    ,
      createDbWriterRoutes('wr-db-oracle', 'oracle', false)
    ,
      createDbWriterRoutes('wr-db-redshift', 'redshift', true)
    ,
      createDbWriterRoutes('wr-tableau', 'mysql', true)
    ]

console.log("routes", routes)

module.exports = routes
