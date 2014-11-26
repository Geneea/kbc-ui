React = require 'react'
Router = require 'react-router'

# actions and stores
OrchestrationsActionCreators = require '../../actions/OrchestrationsActionCreators.coffee'
OrchestrationStore = require '../../stores/OrchestrationStore.coffee'
OrchestrationJobsStore = require '../../stores/OrchestrationJobsStore.coffee'

# React components
OrchestrationsNav = React.createFactory(require './OrchestrationsNav.coffee')
OrchestrationsSearch = React.createFactory(require './OrchestrationsSearch.coffee')
JobsTable = React.createFactory(require './jobs-table/JobsTable.coffee')

{div} = React.DOM


OrchestrationDetail = React.createClass
  displayName: 'OrchestrationDetail'
  mixins: [Router.State]

  statics:
    willTransitionTo: (transition, params, query) ->
      console.log 'will trasition', transition, params, query

  _getOrchestrationId: ->
    # using getParams method provided by Router.State mixin
    parseInt(@getParams().orchestrationId)

  _getStateFromStores: ->
    orchestrationId = @_getOrchestrationId()
    return {
      orchestration: OrchestrationStore.get orchestrationId
      isLoading: OrchestrationStore.getIsOrchestrationLoading orchestrationId
      jobs: OrchestrationJobsStore.getOrchestrationJobs orchestrationId
      jobsLoading: OrchestrationJobsStore.isLoading orchestrationId
    }

  getInitialState: ->
    @_getStateFromStores()

  componentDidMount: ->
    OrchestrationStore.addChangeListener(@_onChange)
    OrchestrationJobsStore.addChangeListener(@_onChange)
    OrchestrationsActionCreators.loadOrchestration(@_getOrchestrationId())
    OrchestrationsActionCreators.loadOrchestrationJobs(@_getOrchestrationId())

  componentWillReceiveProps: ->
    @setState(@_getStateFromStores())
    OrchestrationsActionCreators.loadOrchestration(@_getOrchestrationId())
    OrchestrationsActionCreators.loadOrchestrationJobs(@_getOrchestrationId())

  componentWillUnmount: ->
    OrchestrationStore.removeChangeListener(@_onChange)
    OrchestrationJobsStore.removeChangeListener(@_onChange)

  _onChange: ->
    @setState(@_getStateFromStores())

  render: ->
    console.log 'jobs', @state.jobs
    if @state.isLoading
      text = 'loading ...'
    else
      if @state.orchestration
        text = 'Orchestration ' + @state.orchestration.get('id') + ' ' + @state.orchestration.get('name')
      else
        text = 'Orchestration not found'

    div {className: 'container-fluid'},
      div {className: 'row'},
        div {className: 'col-md-3 kb-orchestrations-sidebar kbc-orchestrations-nav'},
          OrchestrationsSearch()
          OrchestrationsNav()
        div {className: 'col-md-9 kb-orchestrations-main'},
          div {},
            text,
            JobsTable(jobs: @state.jobs.toJS())


module.exports = OrchestrationDetail