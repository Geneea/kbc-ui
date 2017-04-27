React = require 'react'

{button, span, div} = React.DOM

Link = React.createFactory(require('react-router').Link)
RoutesStore = require('../../../../stores/RoutesStore.coffee')
ComponentsStore = require('../../stores/ComponentsStore.coffee')
createStoreMixin = require('../../../../react/mixins/createStoreMixin.coffee')

Modal = React.createFactory(require('react-bootstrap').Modal)
Button = React.createFactory(require('react-bootstrap').Button)
NewComponentModal = React.createFactory(require('../pages/new-component-form/NewComponentModal'))

module.exports = React.createClass
  displayName: 'AddComponentConfigurationButton'

  propTypes:
    component: React.PropTypes.object.isRequired
    label: React.PropTypes.string
    disabled: React.PropTypes.bool

  getInitialState: ->
    showModal: false

  getDefaultProps: ->
    label: 'Add Configuration'

  close: ->
    @setState showModal: false

  open: ->
    @setState showModal: true


  render: ->
    div null,
      button
        className: 'btn btn-success'
        onClick: @open
        disabled: @props.disabled
      ,
        span className: 'kbc-icon-plus'
        @props.label
      Modal
        show: @state.showModal
        onHide: @close
      ,
        NewComponentModal
          component: @props.component
          onClose: @close
