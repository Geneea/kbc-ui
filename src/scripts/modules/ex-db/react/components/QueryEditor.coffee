React = require 'react'
fuzzy = require 'fuzzy'

CodeEditor  = React.createFactory(require('../../../../react/common/common').CodeEditor)
Check = React.createFactory(require('../../../../react/common/common').Check)

Autosuggest = React.createFactory(require 'react-autosuggest')
editorMode = require('../../editorMode').default

{div, table, tbody, tr, td, ul, li, a, span, h2, p, strong, input, label} = React.DOM

createGetSuggestions = (getOptions) ->
  (input, callback) ->
    suggestions = getOptions()
      .filter (value) -> fuzzy.match(input, value)
      .slice 0, 10
      .toList()
    callback(null, suggestions.toJS())


module.exports = React.createClass
  displayName: 'ExDbQueryEditor'
  propTypes:
    query: React.PropTypes.object.isRequired
    tables: React.PropTypes.object.isRequired
    onChange: React.PropTypes.func.isRequired
    showOutputTable: React.PropTypes.bool
    configId: React.PropTypes.string.isRequired
    driver: React.PropTypes.string.isRequired

  _handleOutputTableChange: (newValue) ->
    @props.onChange(@props.query.set 'outputTable', newValue)

  _handlePrimaryKeyChange: (event) ->
    @props.onChange(@props.query.set 'primaryKey', event.target.value)

  _handleIncrementalChange: (event) ->
    @props.onChange(@props.query.set 'incremental', event.target.checked)

  _handleQueryChange: (data) ->
    @props.onChange(@props.query.set 'query', data.value)

  _handleNameChange: (event) ->
    @props.onChange(@props.query.set 'name', event.target.value)

  _tableNamePlaceholder: ->
    "in.c-ex-db-" + @props.configId + "." + @props.query.get('name', '')

  render: ->
    div className: 'row',
      div className: 'form-horizontal',
        div className: 'form-group',
          label className: 'col-md-2 control-label', 'Name'
          div className: 'col-md-4',
            input
              className: 'form-control'
              type: 'text'
              value: @props.query.get 'name'
              ref: 'queryName'
              placeholder: 'Untitled Query'
              onChange: @_handleNameChange
              autoFocus: true
          label className: 'col-md-2 control-label', 'Primary key'
          div className: 'col-md-4',
          input
            className: 'form-control'
            type: 'text'
            value: @props.query.get 'primaryKey'
            placeholder: 'No primary key'
            onChange: @_handlePrimaryKeyChange
        div className: 'form-group',
          label className: 'col-md-2 control-label', 'Output table'
          div className: 'col-md-4',
            Autosuggest
              suggestions: createGetSuggestions(@_tableSelectOptions)
              inputAttributes:
                className: 'form-control'
                placeholder: @_tableNamePlaceholder()
                value: @props.query.get 'outputTable'
                onChange: @_handleOutputTableChange
          div className: 'col-md-4 col-md-offset-2 checkbox',
            label null,
              input
                type: 'checkbox'
                checked: @props.query.get 'incremental'
                onChange: @_handleIncrementalChange
              'Incremental'
        div className: 'form-group',
          label className: 'col-md-12 control-label', 'SQL query'
          div className: 'col-md-12',
            CodeEditor
              readOnly: false
              placeholder: 'SELECT `id`, `name` FROM `myTable`'
              value: @props.query.get 'query'
              mode: editorMode(@props.driver)
              onChange: @_handleQueryChange


  _tableSelectOptions: ->
    @props.tables
    .map (table) ->
      table.get 'id'
    .sortBy (val) -> val
