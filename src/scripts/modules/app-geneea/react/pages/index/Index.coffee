React = require 'react'
Immutable = require('immutable')
{ul, li, span, div, a, p, h2, label, input, form} = React.DOM
Check = React.createFactory(require('kbc-react-components').Check)
_ = require 'underscore'
OverlayTrigger = React.createFactory(require('./../../../../../react/common/KbcBootstrap').OverlayTrigger)
Input = React.createFactory(require('./../../../../../react/common/KbcBootstrap').Input)
TableLink = React.createFactory(require('../../../../components/react/components/StorageApiTableLink').default)
ComponentDescription = require '../../../../components/react/components/ComponentDescription'
ComponentDescription = React.createFactory(ComponentDescription)
ComponentMetadata = require '../../../../components/react/components/ComponentMetadata'
RunButtonModal = React.createFactory(require('../../../../components/react/components/RunComponentButton'))
DeleteConfigurationButton = require '../../../../components/react/components/DeleteConfigurationButton'
DeleteConfigurationButton = React.createFactory DeleteConfigurationButton
LatestJobs = require '../../../../components/react/components/SidebarJobs'

createStoreMixin = require '../../../../../react/mixins/createStoreMixin'
InstalledComponentsStore = require '../../../../components/stores/InstalledComponentsStore'
InstalledComponentsActions = require '../../../../components/InstalledComponentsActionCreators'
storageActionCreators = require '../../../../components/StorageActionCreators'
storageTablesStore = require '../../../../components/stores/StorageTablesStore'
Select = React.createFactory(require('react-select'))
LatestJobsStore = require '../../../../jobs/stores/LatestJobsStore'
fuzzy = require 'fuzzy'
getTemplates = require './../../components/templates'
validation = require './../../components/validation'
RoutesStore = require '../../../../../stores/RoutesStore'
StaticText = React.createFactory(require('./../../../../../react/common/KbcBootstrap').FormControls.Static)
AutoSuggestWrapperComponent = require('../../../../transformations/react/components/mapping/AutoSuggestWrapper').default
AutosuggestWrapper = React.createFactory(AutoSuggestWrapperComponent)

module.exports = (componentId) ->
  React.createClass

    displayName: 'GeneeaAppDetail'

    tooltips: getTemplates(componentId).tooltips
    outTableSuffix: getTemplates(componentId).outputTableSuffix
    actionLabel: getTemplates(componentId).runActionLabel
    runMessage: ->



    mixins: [createStoreMixin(InstalledComponentsStore, storageTablesStore)]
    getStateFromStores: ->
      configId = RoutesStore.getCurrentRouteParam('config')
      configData = InstalledComponentsStore.getConfigData(componentId, configId)
      editingConfigData = InstalledComponentsStore.getEditingConfigData(componentId, configId)

      isComplete = validation(componentId).isComplete(configData)
      runMessage = "You are about to run #{@actionLabel} job of this configuration."
      if not isComplete
        runMessage = "Warning! You are about to run #{@actionLabel} \
        of uncomplete configuration that will most likely fail, please setup configuriation first."
      inputTables = configData?.getIn [ 'storage', 'input', 'tables']
      intable = inputTables?.get(0)?.get 'source'
      outTables = configData?.getIn [ 'storage', 'output', 'tables']
      outTable = outTables?.get(0)?.get 'source'
      parameters = configData?.getIn ['parameters']
      editingData = @_prepareEditingData(editingConfigData)
      isEditing = InstalledComponentsStore.getEditingConfigData(componentId, configId)

      language = null
      if @_isLangParam()
        language = parameters?.get('language') or 'en'
      useBeta = parameters?.get('use_beta') or false

      data_column: parameters?.get 'data_column'
      id_column: parameters?.get 'id_column'
      language: language
      intable: intable
      outtable: outTable
      isEditing: isEditing
      editingData: editingData
      configId: configId
      latestJobs: LatestJobsStore.getJobs componentId, configId
      runMessage: runMessage
      useBeta: useBeta

    componentWillMount: ->
      setTimeout ->
        storageActionCreators.loadTables()
    componentDidMount: ->
      setTimeout ->
        storageActionCreators.loadTables()

    render: ->
      #console.log 'rendering', @state.config.toJS()
      div {className: 'container-fluid'},
        @_renderMainContent()
        @_renderSideBar()

    _renderSideBar: ->
      div {className: 'col-md-3 kbc-main-sidebar'},
        div className: 'kbc-buttons kbc-text-light',
          React.createElement ComponentMetadata,
            componentId: componentId
            configId: @state.configId
        ul className: 'nav nav-stacked',
          if not @state.isEditing
            li null,
              RunButtonModal

                title: "Run #{@actionLabel}"
                mode: 'link'
                component: componentId
                runParams: =>
                  config: @state.configId
              ,
                @state.runMessage
          li null,
            DeleteConfigurationButton
              componentId: componentId
              configId: @state.configId
        React.createElement LatestJobs,
          jobs: @state.latestJobs


    _renderMainContent: ->
      div {className: 'col-md-9 kbc-main-content'},
        div className: 'row',
          ComponentDescription
            componentId: componentId
            configId: @state.configId
        div className: 'row',
          form className: 'form-horizontal',
            if @state.isEditing
              @_renderEditorRow()
            else
              div className: 'row',
                @_createInput('Input Table', @state.intable, @tooltips.intable, true)
                @_createInput('Data Column', @state.data_column, @tooltips.data_column)
                @_createInput('Primary Key', @state.id_column, @tooltips.id_column)
                @_createInput('Output Table', @state.outtable, @tooltips.outtable, @_tableExists(@state.outtable))
                @_createInput('Language', @_getLangLabel(@state.language), @tooltips.language) if @_isLangParam()
                @_renderUseBeta()


    _renderUseBeta: ->
      if @state.isEditing
        div className: 'form-group',
          label className: 'col-xs-2 control-label', 'Use Beta Version'
          div className: 'col-xs-10',
            input
              type: 'checkbox'
              checked: @state.editingData.use_beta
              onChange: (event) =>
                newEditingData = @state.editingData
                newEditingData.use_beta = event.target.checked
                @setState
                  editingData: newEditingData
                @_updateEditingConfig()
      else
        StaticText
          label: 'Use Beta Version'
          labelClassName: 'col-xs-4'
          wrapperClassName: 'col-xs-8'
        , Check isChecked: @state.useBeta


    _renderEditorRow: ->
      div className: 'row',
        div className: 'form-group',
          label className: 'col-xs-2 control-label', 'Source Table'
          div className: 'col-xs-10',
            Select
              key: 'sourcetable'
              name: 'source'
              value: @state.editingData.intable
              placeholder: "Source table"
              onChange: (newValue) =>
                newEditingData = @state.editingData
                newEditingData.intable = newValue
                newEditingData.outtable = "#{newValue}-#{@outTableSuffix}"
                newEditingData.data_column = ""
                newEditingData.id_column = ""
                @setState
                  editingData: newEditingData
                @_updateEditingConfig()
              options: @_getTables()
          ,
            p className: 'help-block', @tooltips.intable

        div className: 'form-group',
          label className: 'col-xs-2 control-label', 'Data Column'
          div className: 'col-xs-10',
            Select
              key: 'datacol'
              name: 'data_column'
              value: @state.editingData.data_column
              placeholder: "Data Column"
              onChange: (newValue) =>
                newEditingData = @state.editingData
                newEditingData.data_column = newValue
                @setState
                  editingData: newEditingData
                @_updateEditingConfig()
              options: @_getColumns()
          ,
            p className: 'help-block', @tooltips.data_column

        div className: 'form-group',
          label className: 'col-xs-2 control-label', 'Primary Key'
          div className: 'col-xs-10',
            Select
              key: 'primcol'
              name: 'id_column'
              value: @state.editingData.id_column
              placeholder: "Primary Key Column"
              onChange: (newValue) =>
                newEditingData = @state.editingData
                newEditingData.id_column = newValue
                @setState
                  editingData: newEditingData
                @_updateEditingConfig()
              options: @_getColumns()
          ,
            p className: 'help-block', @tooltips.id_column

        div className: 'form-group',
          label className: 'control-label col-xs-2', 'Output Table'
          div className: "col-xs-10",
            AutosuggestWrapper
              suggestions: @_getOutTables()
              placeholder: 'to get hint start typing'
              value: @state.editingData.outtable
              onChange: (newValue) =>
                newEditingData = @state.editingData
                newEditingData.outtable = newValue
                @setState
                  editingData: newEditingData
                @_updateEditingConfig()
          ,
            p className: 'help-block', @tooltips.outtable
        if @_isLangParam()
          div className: 'form-group',
            label className: 'col-xs-2 control-label', 'Language'
            div className: 'col-xs-10',
              Select
                key: 'language'
                name: 'language'
                value: @state.editingData.language
                placeholder: "Language Column"
                onChange: (newValue) =>
                  newEditingData = @state.editingData
                  newEditingData.language = newValue
                  @setState
                    editingData: newEditingData
                  @_updateEditingConfig()
                options: [
                  label: 'English'
                  value: 'en'
                ,
                  label: 'Czech'
                  value: 'cs'
                  ]
            ,
              p className: 'help-block', @tooltips.language
        @_renderUseBeta()


    _getTables: ->
      tables = storageTablesStore.getAll()
      tables.filter( (table) ->
        table.getIn(['bucket','stage']) != 'sys').map( (value,key) ->
        {
          label: key
          value: key
        }
        ).toList().toJS()

    _getOutTables: ->
      tables = storageTablesStore.getAll()
      tables.filter( (table) ->
        table.getIn(['bucket','stage']) != 'sys').map( (value,key) ->
        return key
        )

    _getColumns: ->
      tableId = @state.editingData?.intable
      tables = storageTablesStore.getAll()
      if !tableId or !tables
        return []
      table = tables.find((table) ->
        table.get("id") == tableId
      )
      return [] if !table
      result = table.get("columns").map( (column) ->
        {
          label: column
          value: column
        }
      ).toList().toJS()
      return result

    _createInput: (caption, value, tooltip, isTable) ->
      if isTable and not _.isEmpty value
        value = TableLink tableId: value, value
      StaticText
        label: caption
        labelClassName: 'col-xs-4'
        wrapperClassName: 'col-xs-8'
      , value or 'N/A'

    _prepareEditingData: (editingData) ->
      #console.log "editing data", editingData?.toJS()
      getTables = (source) ->
        editingData?.getIn ['storage', source, 'tables']
      params = editingData?.getIn ['parameters']
      language = null
      if @_isLangParam()
        language = params?.get('language') or 'en'

      intable: getTables('input')?.get(0)?.get('source')
      outtable: getTables('output')?.get(0)?.get('source') or ""
      id_column: params?.get 'id_column'
      data_column: params?.get 'data_column'
      language: language
      use_beta: params?.get 'use_beta' or false


    _updateEditingConfig: ->
      setup = @state.editingData
      columns = _.map @_getColumns(), (value, key) ->
        value['value']
      columns = [setup?.id_column, setup?.data_column]
      template =
        storage:
          input:
            tables: [{source: setup.intable, columns: columns}]
          output:
            tables: [{source: setup.outtable, destination: setup.outtable}]
        parameters:
          'use_beta': setup.use_beta
          'id_column': setup.id_column
          data_column: setup.data_column
          user_key: '9cf1a9a51553e32fda1ecf101fc630d5'
          language: setup.language if @_isLangParam()
      updateFn = InstalledComponentsActions.updateEditComponentConfigData
      data = Immutable.fromJS template
      updateFn componentId, @state.configId, data

    _tableExists: (tableId) ->
      tables = storageTablesStore.getAll()
      tables.find( (table) ->
        table.get('id') == tableId)

    _isLangParam: ->
      componentId != 'geneea-language-detection'

    _getLangLabel: (lang) ->
      languages =
        en: 'English'
        cs: 'Czech'
      languages[lang] or "unknown language #{lang}"
