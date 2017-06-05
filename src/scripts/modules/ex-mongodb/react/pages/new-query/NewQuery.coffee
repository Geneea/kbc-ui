React = require 'react'
Map = require('immutable').Map
createStoreMixin = require '../../../../../react/mixins/createStoreMixin'

storeProvisioning = require '../../../storeProvisioning'
actionsProvisioning = require '../../../actionsProvisioning'

RoutesStore = require '../../../../../stores/RoutesStore'
StorageTablesStore = require '../../../../components/stores/StorageTablesStore'

QueryEditor = React.createFactory(require '../../components/QueryEditor')
constants = require './../../../constants'

module.exports = (componentId) ->
  ExDbActionCreators = actionsProvisioning.createActions(componentId)
  React.createClass
    displayName: 'ExDbNewQuery'
    mixins: [createStoreMixin(storeProvisioning.componentsStore, StorageTablesStore)]

    getStateFromStores: ->
      configId = RoutesStore.getRouterState().getIn ['params', 'config']
      ExDbStore = storeProvisioning.createStore(componentId, configId)
      newQuery = ExDbStore.getNewQuery()

      component: storeProvisioning.componentsStore.getComponent(constants.COMPONENT_ID)
      configId: configId
      newQuery: newQuery
      exports: StorageTablesStore.getAll()
      outTableExist: ExDbStore.outTableExist(newQuery)

    _handleQueryChange: (newQuery) ->
      ExDbActionCreators.updateNewQuery @state.configId, newQuery

    render: ->
      React.DOM.div className: 'container-fluid kbc-main-content',
        QueryEditor
          query: @state.newQuery
          exports: @state.exports
          onChange: @_handleQueryChange
          configId: @state.configId
          outTableExist: @state.outTableExist
          componentId: componentId
          component: @state.component
