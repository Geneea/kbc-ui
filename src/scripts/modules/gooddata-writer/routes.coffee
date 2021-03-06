actionCreators = require './actionCreators'
InstalledComponentsStore = require '../components/stores/InstalledComponentsStore'
GoodDataWriterStore = require './store'

IndexPage = require './react/pages/index/Index'
TablePage = require './react/pages/table/Table'
WriterReloader = require('./react/components/WritersReloaderButton').default
TablePageHeaderButtons = require './react/components/TableHeaderButtons'
TablePageHeaderExportStatus = require './react/components/TableHeaderExportStatus'
DateDimensionsPage = require './react/pages/date-dimensions/DateDimensions'
ModelPage = require './react/pages/model/Model'
storageActionCreators = require '../components/StorageActionCreators'
JobsActionCreators = require '../jobs/ActionCreators'
VersionsActionCreators = require '../components/VersionsActionCreators'

module.exports =
  name: 'gooddata-writer'
  path: ':config'
  isComponent: true
  requireData: [
    (params) ->
      actionCreators.loadConfiguration params.config
    ,
      ->
        storageActionCreators.loadTables()
    ,
      (params) ->
        VersionsActionCreators.loadVersions('gooddata-writer', params.config)
  ]
  poll:
    interval: 5
    action: (params) ->
      JobsActionCreators.loadComponentConfigurationLatestJobs('gooddata-writer', params.config)

  defaultRouteHandler: IndexPage
  reloaderHandler: WriterReloader
  title: (routerState) ->
    configId = routerState.getIn ['params', 'config']
    InstalledComponentsStore.getConfig('gooddata-writer', configId).get 'name'
  childRoutes: [
    name: 'gooddata-writer-table'
    path: 'table/:table'
    requireData: [
      (params) ->
        actionCreators.loadTableDetail(params.config, params.table)
    ,
      (params) ->
        actionCreators.loadReferencableTables(params.config)
    ]
    title: (routerState) ->
      configId = routerState.getIn ['params', 'config']
      tableId = routerState.getIn ['params', 'table']
      table = GoodDataWriterStore.getTable(configId, tableId)
      "table #{table.get('id')}"
    handler: TablePage
    headerButtonsHandler: TablePageHeaderButtons
    reloaderHandler: TablePageHeaderExportStatus
  ,
    name: 'gooddata-writer-date-dimensions'
    path: 'dimensions'
    title: ->
      'Date dimensions'
    requireData: [
      (params) ->
        actionCreators.loadDateDimensions params.config
    ]
    handler: DateDimensionsPage
  ,
    name: 'gooddata-writer-model'
    path: 'model'
    title: 'Model'
    handler: ModelPage
  ]
