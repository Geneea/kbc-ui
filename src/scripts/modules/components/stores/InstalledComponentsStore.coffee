Dispatcher = require('../../../Dispatcher')
constants = require '../Constants'
Immutable = require('immutable')
fuzzy = require('fuzzy')
Map = Immutable.Map
List = Immutable.List
StoreUtils = require '../../../utils/StoreUtils'
propagateApiAttributes = require('../react/components/jsoneditor/propagateApiAttributes').default
TemplatesStore = require './TemplatesStore'
ComponentsStore = require './ComponentsStore'
fromJSOrdered = require('../../../utils/fromJSOrdered').default
trashUtils = require('../../trash/utils')

_store = Map(
  configData: Map() #componentId #configId
  configRowsData: Map() #componentId #configId #rowId
  configRows: Map() #componentId #configId #rowId
  configDataLoading: Map() #componentId #configId - configuration detail JSON
  configsDataLoading: Map() #componentId - configurations JSON
  configsDataLoaded: Map() #componentId - configurations JSON
  configDataEditing: Map() #componentId #configId - configuration
  configDataEditingObject: Map() #componentId #configId - configuration
  configDataParametersEditing: Map() #componentId #configId - configuration
  rawConfigDataEditing: Map() #componentId #configId - configuration stringified JSON
  rawConfigDataParametersEditing: Map() #componentId #configId - configuration stringified JSON
  templatedConfigEditing: Map() # componentId #configId
  templatedConfigValuesEditingValues: Map() # componentId #configId
                                      # group (params:Map|templates:Map)
  templatedConfigValuesEditingString: Map() #componentId #configId
  templatedConfigEditingString: Map() #componentId #configId

  #detail JSON
  configDataSaving: Map()
  configDataParametersSaving: Map()
  localState: Map()

  components: Map()
  deletedComponents: Map()
  editingConfigurations: Map()
  editingConfigurationRows: Map()
  savingConfigurations: Map()
  savingConfigurationRows: Map()
  deletingConfigurations: Map()
  restoringConfigurations: Map()
  isLoaded: false
  isLoading: false
  isDeletedLoaded: false
  isDeletedLoading: false
  pendingActions: Map()
  openMappings: Map()

  filters: Map()
)

InstalledComponentsStore = StoreUtils.createStore

  getLocalState: (componentId, configId) ->
    _store.getIn ['localState', componentId, configId], Map()

  getAll: ->
    _store
    .get 'components'
    .map (component) ->
      component.set 'configurations', component.get('configurations').sortBy (configuration) ->
        configuration.get('name').toLowerCase()
    .sortBy (component) -> component.get 'name'

  getAllDeleted: ->
    _store
    .get 'deletedComponents'
    .map (component) ->
      component.set 'configurations', component.get('configurations').sortBy (configuration) ->
        configuration.get('name').toLowerCase()
    .sortBy (component) -> component.get 'name'

  getAllForType: (type) ->
    @getAll().filter (component) ->
      component.get('type') == type

  getFilteredComponents: (type) ->
    filterQuery = @getComponentFilter(type)

    filteredConfigurations = @getAllForType(type)
      .map (component) ->
        return component.set('configurations',
          component.get('configurations', Map()).filter((configuration) ->
            fuzzy.match(filterQuery, configuration.get('name').toString()) or
              fuzzy.match(filterQuery, configuration.get('description').toString())
          )
        )
      .filter (component) ->
        return component.get('configurations').count() > 0

    filteredComponents = @getAllForType(type).filter (component) ->
      fuzzy.match(filterQuery, component.get('name'))
    filtered = filteredComponents.mergeDeep(filteredConfigurations)

    return filtered


  getComponentFilter: (filterType) ->
    _store.getIn ['filters', 'installedComponents', filterType], ''

  getTrashFilter: (filterType) ->
    _store.getIn ['filters', 'trash', filterType], ''

  getAllDeletedFiltered: ->
    nameFilter = @getTrashFilter('name')
    typeFilter = @getTrashFilter('type')
    components = @getAllDeleted()

    if (typeFilter && typeFilter isnt '')
      components = components.filter(
        (component) ->
          if (typeFilter is 'orchestrator')
            component.get('id').toString() is typeFilter
          else
            component.get('type').toString() is typeFilter
      )

    if (!nameFilter || nameFilter is '')
      components
    else
      components.filter(
        (component) ->
          (
            fuzzy.match(nameFilter, component.get('name').toString()) or
              fuzzy.match(nameFilter, component.get('id').toString()) or
              @getAllDeletedConfigurationsFiltered(component).count()
          )
        ,
        @
      )

  getAllDeletedConfigurationsFiltered: (component) ->
    filter = @getTrashFilter('name')
    configurations = component.get('configurations', Map())

    if !filter || filter is ''
      configurations
    else
      configurations.filter(
        (configuration) ->
          fuzzy.match(filter, configuration.get('name').toString()) or
          fuzzy.match(filter, configuration.get('description').toString()) or
          fuzzy.match(filter, configuration.get('id', '').toString())
        ,
        @
      )

  getAllDeletedForType: (type) ->
    @getAllDeleted().filter (component) ->
      component.get('type') == type


  getConfigurationFilter: (type) ->
    _store.getIn ['filters', 'installedComponents', type], ''

  getComponent: (componentId) ->
    _store.getIn ['components', componentId]

  getIsConfigDataLoaded: (componentId, configId) ->
    _store.hasIn ['configData', componentId, configId]

  getIsConfigsDataLoaded: (componentId) ->
    _store.getIn ['configsDataLoaded', componentId], false

  getEditingConfigData: (componentId, configId, defaultValue) ->
    _store.getIn ['configDataEditing', componentId, configId], defaultValue

  getEditingRawConfigData: (componentId, configId, defaultValue) ->
    _store.getIn ['rawConfigDataEditing', componentId, configId], defaultValue

  getEditingRawConfigDataParameters: (componentId, configId, defaultValue) ->
    _store.getIn ['rawConfigDataParametersEditing', componentId, configId], defaultValue

  getSavingConfigData: (componentId, configId) ->
    _store.getIn ['configDataSaving', componentId, configId]

  getSavingConfigDataParameters: (componentId, configId) ->
    _store.getIn ['configDataParametersSaving', componentId, configId]

  getConfigData: (componentId, configId) ->
    _store.getIn ['configData', componentId, configId], Map()

  getEditingConfigDataObject: (componentId, configId) ->
    _store.getIn ['configDataEditingObject', componentId, configId], Map()

  getConfigDataParameters: (componentId, configId) ->
    _store.getIn(['configData', componentId, configId, 'parameters'], Map())

  getConfig: (componentId, configId) ->
    _store.getIn(['components', componentId, 'configurations', configId], Map())

  getDeletedConfig: (componentId, configId) ->
    _store.getIn ['deletedComponents', componentId, 'configurations', configId]

  getConfigRow: (componentId, configId, rowId) ->
    _store.getIn ['configRows', componentId, configId, rowId], Map()

  getConfigRowData: (componentId, configId, rowId) ->
    _store.getIn ['configRowsData', componentId, configId, rowId], Map()

  isEditingConfig: (componentId, configId, field) ->
    _store.hasIn ['editingConfigurations', componentId, configId, field]

  isEditingConfigRow: (componentId, configId, rowId, field) ->
    _store.hasIn ['editingConfigurationRows', componentId, configId, rowId, field]

  isEditingConfigData: (componentId, configId) ->
    _store.hasIn ['editingConfigData', componentId, configId]

  isEditingRawConfigData: (componentId, configId) ->
    _store.hasIn ['rawConfigDataEditing', componentId, configId]

  isEditingRawConfigDataParameters: (componentId, configId) ->
    _store.hasIn ['rawConfigDataParametersEditing', componentId, configId]

  isEditingTemplatedConfig: (componentId, configId) ->
    _store.getIn(['templatedConfigEditing', componentId, configId], false)

  getEditingConfig: (componentId, configId, field) ->
    _store.getIn ['editingConfigurations', componentId, configId, field]

  getEditingConfigRow: (componentId, configId, rowId, field) ->
    _store.getIn ['editingConfigurationRows', componentId, configId, rowId, field]


  isValidEditingConfig: (componentId, configId, field) ->
    value = @getEditingConfig(componentId, configId, field)
    return true if value == undefined
    switch field
      when 'description' then true
      when 'name' then value.trim().length > 0

  isValidEditingConfigRow: (componentId, configId, rowId, field) ->
    value = @getEditingConfig(componentId, configId, rowId, field)
    return true if value == undefined
    switch field
      when 'description' then true
      when 'name' then value.trim().length > 0

  isValidEditingConfigData: (componentId, configId) ->
    value = @getEditingRawConfigData(componentId, configId)
    try
      JSON.parse(value)
      return true
    return false

  isValidEditingConfigDataParameters: (componentId, configId) ->
    value = @getEditingRawConfigDataParameters(componentId, configId)
    try
      JSON.parse(value)
      return true
    return false

  getRestoringConfigurations: ->
    _store.get 'restoringConfigurations'

  getDeletingConfigurations: ->
    _store.get 'deletingConfigurations'

  isDeletingConfig: (componentId, configId) ->
    _store.hasIn ['deletingConfigurations', componentId, configId]

  isSavingConfig: (componentId, configId, field) ->
    _store.hasIn ['savingConfigurations', componentId, configId, field]

  isSavingConfigRow: (componentId, configId, rowId, field) ->
    _store.hasIn ['savingConfigurationRows', componentId, configId, rowId, field]

  isSavingConfigData: (componentId, configId) ->
    _store.hasIn ['configDataSaving', componentId, configId]

  isSavingConfigDataParameters: (componentId, configId) ->
    _store.hasIn ['configDataParametersSaving', componentId, configId]

  getIsLoading: ->
    _store.get 'isLoading'

  getIsLoaded: ->
    _store.get 'isLoaded'

  getIsDeletedLoading: ->
    _store.get 'isDeletedLoading'

  getIsDeletedLoaded: ->
    _store.get 'isDeletedLoaded'

  getPendingActions: (componentId, configId) ->
    _store.getIn ['pendingActions', componentId, configId], Map()

  getOpenMappings: (componentId, configId) ->
    _store.getIn ['openMappings', componentId, configId], Map()

  # new
  getTemplatedConfigValueConfig: (componentId, configId) ->
    _store.getIn(['configData', componentId, configId, 'parameters', 'config'], Immutable.Map())

  getTemplatedConfigValueUserParams: (componentId, configId) ->
    config = _store.getIn(['configData', componentId, configId, 'parameters', 'config'], Immutable.Map())
    # delete keys from template if template matches
    template = TemplatesStore.getMatchingTemplate(componentId, config)
    if (!template.isEmpty())
      template.get('data').keySeq().forEach((key) ->
        config = config.delete(key)
      )
    return config

  getTemplatedConfigValueWithoutUserParams: (componentId, configId) ->
    config = _store.getIn(['configData', componentId, configId, 'parameters', 'config'], Immutable.Map())
    # delete schema keys from config
    ComponentsStore.getComponent(componentId)
    .get('configurationSchema', Immutable.Map())
    .getIn(['properties'], Immutable.Map())
    .keySeq()
    .forEach((key) ->
      config = config.delete(key)
    )
    return config

  getTemplatedConfigEditingValueParams: (componentId, configId) ->
    _store.getIn(['templatedConfigValuesEditingValues', componentId, configId, 'params'], Immutable.Map())

  getTemplatedConfigEditingValueTemplate: (componentId, configId) ->
    _store.getIn(['templatedConfigValuesEditingValues', componentId, configId, 'template'], Immutable.Map())

  getTemplatedConfigEditingValueString: (componentId, configId) ->
    _store.getIn(['templatedConfigValuesEditingString', componentId, configId], '{}')

  isTemplatedConfigEditingString: (componentId, configId) ->
    _store.getIn(['templatedConfigEditingString', componentId, configId]) || false


Dispatcher.register (payload) ->
  action = payload.action

  switch action.type
    when constants.ActionTypes.INSTALLED_COMPONENTS_LOCAL_STATE_UPDATE
      data = action.data
      path = ['localState', action.componentId, action.configId]
      _store = _store.setIn path, data
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_EDIT_START
      path = ['configDataEditing', action.componentId, action.configId]
      configData = InstalledComponentsStore.getConfigData(action.componentId, action.configId)
      _store = _store.setIn path, configData
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_EDIT_UPDATE
      path = ['configDataEditing', action.componentId, action.configId]
      configData = action.data
      _store = _store.setIn path, configData
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_EDIT_CANCEL
      path = ['configDataEditing', action.componentId, action.configId]
      _store = _store.deleteIn path
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATA_EDIT_START
      path = ['rawConfigDataEditing', action.componentId, action.configId]
      configData = InstalledComponentsStore.getConfigData(action.componentId, action.configId)
      _store = _store.setIn path, JSON.stringify(configData, null, '  ')
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATA_EDIT_UPDATE
      path = ['rawConfigDataEditing', action.componentId, action.configId]
      configData = action.data
      _store = _store.setIn path, configData
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATA_EDIT_CANCEL
      path = ['rawConfigDataEditing', action.componentId, action.configId]
      _store = _store.deleteIn path
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATAPARAMETERS_EDIT_START
      path = ['rawConfigDataParametersEditing', action.componentId, action.configId]
      configData = InstalledComponentsStore.getConfigDataParameters(action.componentId, action.configId)
      _store = _store.setIn path, JSON.stringify(configData, null, '  ')
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATAPARAMETERS_EDIT_UPDATE
      path = ['rawConfigDataParametersEditing', action.componentId, action.configId]
      configData = action.data
      _store = _store.setIn path, configData
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATAPARAMETERS_EDIT_CANCEL
      path = ['rawConfigDataParametersEditing', action.componentId, action.configId]
      _store = _store.deleteIn path
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_LOAD
      _store = _store.setIn ['configDataLoading', action.componentId, action.configId], true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_LOAD_SUCCESS
      _store = _store.deleteIn ['configDataLoading', action.componentId, action.configId]
      storePath = ['configData', action.componentId, action.configId]
      _store = _store.setIn storePath, fromJSOrdered(action.configData)
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_LOAD_ERROR
      _store = _store.deleteIn ['configDataLoading', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGSDATA_LOAD
      _store = _store.setIn ['configsDataLoading', action.componentId], true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGSDATA_LOAD_SUCCESS
      _store = _store.withMutations (store) ->
        store = store
          .deleteIn ['configsDataLoading', action.componentId]
          .setIn ['configsDataLoaded', action.componentId], true

        i = 0
        while i < action.configData.length
          store = store.setIn [
            'components', action.componentId, 'configurations', action.configData[i].id
          ], fromJSOrdered(action.configData[i])
          j = 0
          while j < action.configData[i].rows.length
            store = store.setIn [
              'configRowsData', action.componentId, action.configData[i].id, action.configData[i].rows[j].id
            ], fromJSOrdered(action.configData[i].rows[j].configuration)
            store = store.setIn [
              'configRows', action.componentId, action.configData[i].id, action.configData[i].rows[j].id
            ], Immutable.fromJS(action.configData[i].rows[j])
            j++
          i++

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGSDATA_LOAD_ERROR
      _store = _store.deleteIn ['configsDataLoading', action.componentId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATA_SAVE_START
      componentId = action.componentId
      configId = action.configId
      editingDataJson = JSON.parse(InstalledComponentsStore.getEditingRawConfigData(componentId, configId))

      editingData = fromJSOrdered editingDataJson

      dataToSave = editingData
      _store = _store.setIn ['configDataSaving', componentId, configId], dataToSave

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATA_SAVE_SUCCESS
      configDataObject = fromJSOrdered(action.configData)
      _store = _store.setIn ['configData', action.componentId, action.configId], configDataObject
      _store = _store.deleteIn ['configDataSaving', action.componentId, action.configId]
      _store = _store.deleteIn ['rawConfigDataEditing', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATA_SAVE_ERROR
      _store = _store.deleteIn ['configDataSaving', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATAPARAMETERS_SAVE_START
      componentId = action.componentId
      configId = action.configId
      editingDataJson = JSON.parse(InstalledComponentsStore.getEditingRawConfigDataParameters(componentId, configId))
      editingData = fromJSOrdered(editingDataJson)
      dataToSave = editingData
      _store = _store.setIn ['configDataParametersSaving', componentId, configId], dataToSave

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATAPARAMETERS_SAVE_SUCCESS
      configDataObject = fromJSOrdered(action.configData).get 'parameters'
      path = ['configData', action.componentId, action.configId, 'parameters']
      _store = _store.setIn path, configDataObject
      _store = _store.deleteIn ['configDataParametersSaving', action.componentId, action.configId]
      _store = _store.deleteIn ['rawConfigDataParametersEditing', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_RAWCONFIGDATAPARAMETERS_SAVE_ERROR
      _store = _store.deleteIn ['configDataParametersSaving', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_SAVE_START
      componentId = action.componentId
      configId = action.configId
      forceData = action.forceData
      editingData = InstalledComponentsStore.getEditingConfigData(componentId, configId)
      dataToSave = forceData or editingData
      _store = _store.setIn ['configDataSaving', componentId, configId], dataToSave

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_SAVE_SUCCESS
      _store = _store.setIn ['configData', action.componentId, action.configId], fromJSOrdered(action.configData)
      _store = _store.deleteIn ['configDataSaving', action.componentId, action.configId]
      _store = _store.deleteIn ['configDataEditing', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGDATA_SAVE_ERROR
      _store = _store.deleteIn ['configDataSaving', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()


    when constants.ActionTypes.INSTALLED_COMPONENTS_LOAD
      _store = _store.set 'isLoading', true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_LOAD_ERROR
      _store = _store.set 'isLoading', false
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_EDIT_START
      _store = _store.withMutations (store) ->
        store.setIn ['editingConfigurations', action.componentId, action.configurationId, action.field],
          InstalledComponentsStore.getConfig(action.componentId, action.configurationId).get action.field
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_EDIT_UPDATE
      _store = _store.setIn ['editingConfigurations', action.componentId, action.configurationId, action.field],
        action.value
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_EDIT_CANCEL
      _store = _store.deleteIn ['editingConfigurations', action.componentId, action.configurationId, action.field]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_DELETE_CONFIGURATION_START
      _store = _store.setIn ['deletingConfigurations', action.componentId, action.configurationId], true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_DELETE_CONFIGURATION_SUCCESS
      _store = _store.withMutations (store) ->
        store
        .deleteIn ['components', action.componentId, 'configurations', action.configurationId]
        .deleteIn ['deletingConfigurations', action.componentId, action.configurationId]

        if !store.getIn(['components', action.componentId, 'configurations']).count()
          store = store.deleteIn ['components', action.componentId]

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_DELETE_CONFIGURATION_START
      _store = _store.setIn ['deletingConfigurations', action.componentId, action.configurationId], true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_FILTER_CHANGE
      _store = _store.setIn ['filters', 'trash', action.filterType], action.filter
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_DELETE_CONFIGURATION_SUCCESS
      _store = _store.withMutations (store) ->
        store
          .deleteIn ['deletedComponents', action.componentId, 'configurations', action.configurationId]
          .deleteIn ['deletingConfigurations', action.componentId, action.configurationId]

        if !store.getIn(['deletedComponents', action.componentId, 'configurations']).count()
          store = store.deleteIn ['deletedComponents', action.componentId]

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_DELETE_CONFIGURATION_ERROR
      _store = _store.deleteIn ['deletingConfigurations', action.componentId, action.configurationId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_DELETE_CONFIGURATION_ERROR
      _store = _store.deleteIn ['deletingConfigurations', action.componentId, action.configurationId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_RESTORE_CONFIGURATION_START
      _store = _store.setIn ['restoringConfigurations', action.componentId, action.configurationId], true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_RESTORE_CONFIGURATION_SUCCESS
      _store = _store.withMutations (store) ->
        store
        .deleteIn ['deletedComponents', action.componentId, 'configurations', action.configurationId]
        .deleteIn ['restoringConfigurations', action.componentId, action.configurationId]

        if !store.getIn(['deletedComponents', action.componentId, 'configurations'], Immutable.Map()).count()
          store = store.deleteIn ['deletedComponents', action.componentId]

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_RESTORE_CONFIGURATION_ERROR
      _store = _store.deleteIn ['restoringConfigurations', action.componentId, action.configurationId]
      InstalledComponentsStore.emitChange()


    when constants.ActionTypes.INSTALLED_COMPONENTS_UPDATE_CONFIGURATION_START
      _store = _store.setIn ['savingConfigurations', action.componentId, action.configurationId, action.field], true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_UPDATE_CONFIGURATION_ERROR
      _store = _store.deleteIn ['savingConfigurations', action.componentId, action.configurationId, action.field]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_UPDATE_CONFIGURATION_SUCCESS
      _store = _store.withMutations (store) ->
        store
          .mergeIn ['components', action.componentId, 'configurations', action.configurationId],
          fromJSOrdered(action.data)
          .deleteIn ['savingConfigurations', action.componentId, action.configurationId, action.field]
          .deleteIn ['editingConfigurations', action.componentId, action.configurationId, action.field]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_LOAD_SUCCESS
      _store = _store.withMutations((store) ->
        store
          .set('isLoading', false)
          .set('isLoaded', true)
          .set('components',
            ## convert to by key structure
            fromJSOrdered(action.components)
            .toMap()
            .map((component) ->
              component.set 'configurations', component.get('configurations').toMap().mapKeys((key, config) ->
                config.get 'id'
              )
            )
            .mapKeys((key, component) ->
              component.get 'id'
            ))
      )
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_LOAD
      _store = _store.set 'isDeletedLoading', true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_LOAD_ERROR
      _store = _store.set 'isDeletedLoading', false
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.DELETED_COMPONENTS_LOAD_SUCCESS
      _store = _store.withMutations((store) ->
        store
          .set('isDeletedLoading', false)
          .set('isDeletedLoaded', true)
          .set('deletedComponents',
            ## convert to by key structure
            fromJSOrdered(action.components)
            .toMap()
            .map((component) ->
              component.set 'configurations', component.get('configurations').toMap().mapKeys((key, config) ->
                config.get 'id'
              )
            )
            .mapKeys((key, component) ->
              component.get 'id'
            ))
      )
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.COMPONENTS_NEW_CONFIGURATION_SAVE_SUCCESS
      _store = _store.withMutations (store) ->
        if !store.hasIn ['components', action.componentId]
          store = store.setIn(['components', action.componentId], action.component.set('configurations', Map()))

        store.setIn ['components', action.componentId, 'configurations', action.configuration.id],
          fromJSOrdered action.configuration

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_TOGGLE_MAPPING
      if (_store.getIn(['openMappings', action.componentId, action.configId, action.index], false))
        _store = _store.setIn(['openMappings', action.componentId, action.configId, action.index], false)
      else
        _store = _store.setIn(['openMappings', action.componentId, action.configId, action.index], true)

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_EDITING_START
      currentMapping = InstalledComponentsStore.getConfigData(action.componentId, action.configId)
      .getIn(['storage', action.mappingType, action.storage, action.index], Map())
      path = [
        'configDataEditingObject', action.componentId,
        action.configId, 'storage', action.mappingType, action.storage, action.index
      ]
      pathList = [
        'configDataEditingObject', action.componentId,
        action.configId, 'storage', action.mappingType, action.storage
      ]

      if (!_store.hasIn(pathList))
        _store = _store.setIn(pathList, List())

      _store = _store.setIn(path, currentMapping)
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_EDITING_CANCEL
      path = [
        'configDataEditingObject', action.componentId,
        action.configId, 'storage', action.mappingType, action.storage, action.index
      ]
      _store = _store.deleteIn(path)
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_EDITING_CHANGE
      path = [
        'configDataEditingObject', action.componentId,
        action.configId, 'storage', action.mappingType, action.storage, action.index
      ]
      _store = _store.setIn(path, action.value)
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_SAVE_START
      path = [
        'pendingActions', action.componentId,
        action.configId, action.mappingType, action.storage, action.index, 'save'
      ]
      _store = _store.setIn(path, true)
      InstalledComponentsStore.emitChange()


    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_SAVE_SUCCESS
      _store = _store.withMutations (store) ->
        path = [
          'pendingActions', action.componentId,
          action.configId, action.mappingType, action.storage, action.index, 'save'
        ]
        store = store.deleteIn(path)

        path = [
          'configDataEditingObject', action.componentId, action.configId,
          'storage', action.mappingType, action.storage, action.index
        ]
        store = store.deleteIn(path)

        storePath = ['configData', action.componentId, action.configId]
        store.setIn storePath, fromJSOrdered(action.data.configuration)

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_SAVE_ERROR
      _store = _store.withMutations (store) ->
        path = [
          'pendingActions', action.componentId,
          action.configId, action.mappingType, action.storage, action.index, 'save'
        ]
        store = store.deleteIn(path)

        path = [
          'configDataEditingObject', action.componentId,action.configId,
          'storage', action.mappingType, action.storage, action.index
        ]
        store.deleteIn(path)

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_DELETE_START
      path = [
        'pendingActions', action.componentId,
        action.configId, action.mappingType, action.storage, action.index, 'delete'
      ]
      _store = _store.setIn(path, true)
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_DELETE_SUCCESS
      _store = _store.withMutations (store) ->
        path = [
          'pendingActions', action.componentId,
          action.configId, action.mappingType, action.storage, action.index, 'delete'
        ]
        store = store.deleteIn(path)

        storePath = ['configData', action.componentId, action.configId]
        store.setIn storePath, fromJSOrdered(action.data.configuration)

      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_MAPPING_DELETE_ERROR
      path = [
        'pendingActions', action.componentId,
        action.configId, action.mappingType, action.storage, action.index, 'delete'
      ]
      _store = _store.deleteIn(path)
      InstalledComponentsStore.emitChange()


    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_START
      _store = _store.withMutations (store) ->
        store = store.setIn(["templatedConfigEditing", action.componentId, action.configId], true)
        config = InstalledComponentsStore.getTemplatedConfigValueConfig(action.componentId, action.configId)
        # compare with templates
        if TemplatesStore.isConfigTemplate(action.componentId, config) ||
            InstalledComponentsStore.
            getTemplatedConfigValueWithoutUserParams(action.componentId, action.configId).
            isEmpty()
          store = store.setIn(
            ["templatedConfigValuesEditingValues", action.componentId, action.configId, "template"],
            TemplatesStore.getMatchingTemplate(action.componentId, config)
          )

          params = InstalledComponentsStore.getTemplatedConfigValueUserParams(action.componentId, action.configId)
          store = store.setIn(
            ["templatedConfigValuesEditingValues", action.componentId, action.configId, "params"],
            params
          )
        # string edit
        else
          store = store.setIn(["templatedConfigEditingString", action.componentId, action.configId], true)
          store = store.setIn(
            ["templatedConfigValuesEditingString", action.componentId, action.configId],
            JSON.stringify(config.toJS(), null, 2)
          )
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_CANCEL
      _store = _store.deleteIn(["templatedConfigValuesEditingValues", action.componentId, action.configId])
      _store = _store.deleteIn(["templatedConfigValuesEditingString", action.componentId, action.configId])
      _store = _store.deleteIn(["templatedConfigEditingString", action.componentId, action.configId])
      _store = _store.deleteIn(["templatedConfigEditing", action.componentId, action.configId])
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_UPDATE_TEMPLATE
      _store = _store.setIn(
        ["templatedConfigValuesEditingValues", action.componentId, action.configId, "template"],
        action.template
      )
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_UPDATE_PARAMS
      _store = _store.setIn(
        ["templatedConfigValuesEditingValues", action.componentId, action.configId, "params"],
        action.value
      )
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_UPDATE_STRING
      _store = _store.setIn(
        ["templatedConfigValuesEditingString", action.componentId, action.configId],
        action.value
      )
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_SAVE_START
      configData = InstalledComponentsStore.getConfigData(action.componentId, action.configId) or Map()
      editingData = configData

      editingData = editingData.setIn(
        ['parameters', 'api'],
        TemplatesStore.getApiTemplate(action.componentId)
      )

      if (_store.getIn(['templatedConfigEditingString', action.componentId, action.configId], false))
        editingData = editingData.setIn(
          ['parameters', 'config'],
          fromJSOrdered(
            JSON.parse(
              _store.getIn(
                ['templatedConfigValuesEditingString', action.componentId, action.configId]
              )
            )
          )
        )
      else
        # params on the first place
        editingData = editingData.setIn(
          ['parameters', 'config'],
          _store.getIn(['templatedConfigValuesEditingValues', action.componentId, action.configId, 'params'], Map())
        )

        # merge the template
        editingData = editingData.setIn(
          ['parameters', 'config'],
          editingData.getIn(['parameters', 'config'], Map()).merge(
            _store.getIn(
              ['templatedConfigValuesEditingValues', action.componentId, action.configId, 'template', 'data'],
              Map()
            )
          )
        )

      _store = _store.setIn ['configDataSaving', action.componentId, action.configId], editingData
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_SAVE_SUCCESS
      _store = _store.setIn(
        ['configData', action.componentId, action.configId],
        fromJSOrdered(action.configData)
      )
      _store = _store.deleteIn(['templatedConfigValuesEditingValues', action.componentId, action.configId])
      _store = _store.deleteIn(['templatedConfigValuesEditingString', action.componentId, action.configId])
      _store = _store.deleteIn(["templatedConfigEditing", action.componentId, action.configId])
      _store = _store.deleteIn(["templatedConfigEditingString", action.componentId, action.configId])
      _store = _store.deleteIn ['configDataSaving', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_SAVE_ERROR
      _store = _store.deleteIn(['templatedConfigValuesEditingValues', action.componentId, action.configId])
      _store = _store.deleteIn(['templatedConfigValuesEditingString', action.componentId, action.configId])
      _store = _store.deleteIn(["templatedConfigEditing", action.componentId, action.configId])
      _store = _store.deleteIn(["templatedConfigEditingString", action.componentId, action.configId])
      _store = _store.deleteIn ['configDataSaving', action.componentId, action.configId]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_TEMPLATED_CONFIGURATION_EDIT_STRING_TOGGLE
      if action.isStringEditingMode

        # params on the first place
        mergedConfig = _store.getIn(
          ['templatedConfigValuesEditingValues', action.componentId, action.configId, 'params'],
          Map()
        )

        # merge the template
        mergedConfig = mergedConfig.merge(
          _store.getIn(
            ['templatedConfigValuesEditingValues', action.componentId, action.configId, 'template', 'data'],
            Map()
          )
        )

        _store = _store.withMutations (store) ->
          store = store.setIn(
            ["templatedConfigValuesEditingString", action.componentId, action.configId],
            JSON.stringify(
              mergedConfig.toJS(),
              null,
              2
            )
          )
          store = store.setIn(["templatedConfigEditingString", action.componentId, action.configId], true)
      else
        _store = _store.deleteIn(["templatedConfigValuesEditingString", action.componentId, action.configId])
        _store = _store.deleteIn(["templatedConfigEditingString", action.componentId, action.configId])
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_SEARCH_CONFIGURATION_FILTER_CHANGE
      _store = _store.setIn ['filters', 'installedComponents', action.componentType], action.filter
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_ROW_EDIT_START
      value = InstalledComponentsStore.getConfigRow(
        action.componentId, action.configurationId, action.rowId
      ).get action.field
      if value == '' && action.fallbackValue
        value = action.fallbackValue
      _store = _store.withMutations (store) ->
        store.setIn [
          'editingConfigurationRows', action.componentId, action.configurationId, action.rowId, action.field
          ]
        ,
          value
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_ROW_EDIT_UPDATE
      _store = _store.setIn [
        'editingConfigurationRows', action.componentId, action.configurationId, action.rowId, action.field
        ]
      ,
        action.value
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_CONFIGURATION_ROW_EDIT_CANCEL
      _store = _store.deleteIn [
        'editingConfigurationRows', action.componentId, action.configurationId, action.rowId, action.field
      ]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_UPDATE_CONFIGURATION_ROW_START
      _store = _store.setIn [
        'savingConfigurationRows', action.componentId, action.configurationId, action.rowId, action.field
      ], true
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_UPDATE_CONFIGURATION_ROW_ERROR
      _store = _store.deleteIn [
        'savingConfigurationRows', action.componentId, action.configurationId, action.rowId, action.field
      ]
      InstalledComponentsStore.emitChange()

    when constants.ActionTypes.INSTALLED_COMPONENTS_UPDATE_CONFIGURATION_ROW_SUCCESS
      _store = _store.withMutations (store) ->
        store
          .mergeIn ['configRows', action.componentId, action.configurationId, action.rowId],
          fromJSOrdered(action.data)
          .deleteIn ['savingConfigurationRows', action.componentId, action.configurationId, action.rowId, action.field]
          .deleteIn ['editingConfigurationRows', action.componentId, action.configurationId, action.rowId, action.field]
      InstalledComponentsStore.emitChange()

module.exports = InstalledComponentsStore
