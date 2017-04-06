React = require 'react'
ImmutableRenderMixin = require '../../../../../../react/mixins/ImmutableRendererMixin'
{Input, Button, ListGroup, ListGroupItem} = require('react-bootstrap')
Input = React.createFactory Input
Button = React.createFactory Button
ListGroup = React.createFactory ListGroup
ListGroupItem = React.createFactory ListGroupItem
Select = React.createFactory(require('react-select'))
_ = require('underscore')

module.exports = React.createClass
  displayName: 'RedshiftDataTypes'
  mixins: [ImmutableRenderMixin]

  propTypes:
    datatypes: React.PropTypes.object.isRequired
    columnValue: React.PropTypes.string.isRequired
    datatypeValue: React.PropTypes.string.isRequired
    sizeValue: React.PropTypes.string.isRequired
    columnsOptions: React.PropTypes.array.isRequired
    datatypeOptions: React.PropTypes.array.isRequired
    disabled: React.PropTypes.bool.isRequired
    showSize: React.PropTypes.bool.isRequired

    handleAddDataType: React.PropTypes.func.isRequired
    handleRemoveDataType: React.PropTypes.func.isRequired
    columnOnChange: React.PropTypes.func.isRequired
    datatypeOnChange: React.PropTypes.func.isRequired
    sizeOnChange: React.PropTypes.func.isRequired


  _handleSizeOnChange: (e) ->
    @props.sizeOnChange(e.target.value)

  _getColumnsOptions: ->
    component = @
    _.filter(@props.columnsOptions, (option) ->
      !_.contains(_.keys(component.props.datatypes.toJS()), option.value)
    )

  _getDatatypeOptions: ->
    component = @
    _.map(@props.datatypeOptions, (datatype) ->
      {
        label: datatype
        value: datatype
      }
    )

  render: ->
    component = @
    React.DOM.span {},
      React.DOM.div {className: "row"},
        React.DOM.span {className: "col-xs-12"},
        if !@props.datatypes.count()
          React.DOM.div {}, React.DOM.small {}, "No data types set yet."
        else
          ListGroup {},
            @props.datatypes.sort().map((datatype, key) ->
              ListGroupItem {key: key},
                  React.DOM.small {},
                    React.DOM.strong {}, key
                    " "
                    React.DOM.span {}, datatype
                    React.DOM.i
                      className: "kbc-icon-cup kbc-cursor-pointer pull-right"
                      onClick: ->
                        component.props.handleRemoveDataType(key)
            , @).toArray()
      React.DOM.div {className: "row"},
        React.DOM.span {className: "col-xs-3"},
          Select
            name: 'add-column'
            value: @props.columnValue
            disabled: @props.disabled
            placeholder: "Column"
            onChange: @props.columnOnChange
            options: @_getColumnsOptions()
        React.DOM.span {className: "col-xs-4"},
          Select
            name: 'add-datatype'
            value: @props.datatypeValue
            disabled: @props.disabled
            placeholder: "Datatype"
            onChange: @props.datatypeOnChange
            options: @_getDatatypeOptions()
        React.DOM.span {className: "col-xs-3"},
          if @props.showSize
            Input
              bsSize: 'small'
              type: 'text'
              name: 'add-size'
              value: @props.sizeValue
              disabled: @props.disabled || !@props.showSize
              placeholder: "Eg. 38,0"
              onChange: @_handleSizeOnChange
        React.DOM.span {className: "col-xs-1"},
          Button
            bsSize: 'small'
            onClick: @props.handleAddDataType
            disabled: @props.disabled || !@props.columnValue || !@props.datatypeValue
          ,
            React.DOM.i {className: "kbc-icon-plus"}
            " Add"
      React.DOM.div {className: "row", style: {paddingTop: "5px"}},
        React.DOM.div {className: "help-block col-xs-12"},
          React.DOM.small {},
            React.DOM.div {},
              React.DOM.code {}, "VARCHAR(255)"
              "default for primary key columns"
            React.DOM.div {},
              React.DOM.code {}, "VARCHAR NOT NULL"
              "default for all other columns"
