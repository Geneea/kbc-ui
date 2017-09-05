React = require 'react'
Navigation = require('react-router').Navigation
createStoreMixin = require '../../../../react/mixins/createStoreMixin'

RoutesStore = require '../../../../stores/RoutesStore'

Loader = React.createFactory(require('kbc-react-components').Loader)

{button, span} = React.DOM

module.exports = (componentId, actionsProvisioning, storeProvisioning) ->
  ExDbActionCreators = actionsProvisioning.createActions(componentId)
  return React.createClass
    displayName: 'NewQueryHeaderButtons'
    mixins: [createStoreMixin(storeProvisioning.componentsStore), Navigation]

    getStateFromStores: ->
      configId = RoutesStore.getCurrentRouteParam 'config'
      ExDbStore = storeProvisioning.createStore(componentId, configId)
      currentConfigId: configId
      isSaving: ExDbStore.isSavingNewQuery()
      isValid: ExDbStore.isValidNewQuery()

    _handleCancel: ->
      ExDbActionCreators.resetNewQuery @state.currentConfigId
      @transitionTo componentId, config: @state.currentConfigId

    _handleCreate: ->
      ExDbActionCreators
      .createQuery @state.currentConfigId
      .then (query) =>
        @transitionTo componentId,
          config: @state.currentConfigId

    render: ->
      React.DOM.div className: 'kbc-buttons',
        if @state.isSaving
          Loader()
        button
          className: 'btn btn-link'
          onClick: @_handleCancel
          disabled: @state.isSaving
        ,
          'Cancel'
        button
          className: 'btn btn-success'
          onClick: @_handleCreate
          disabled: @state.isSaving || !@state.isValid
        ,
          'Create Query'
