React = require('react')
ActionCreators = require '../../../exGdriveActionCreators'
ImmutableRenderMixin = require '../../../../../react/mixins/ImmutableRendererMixin'
{ ListGroup, ListGroupItem } = require('react-bootstrap')

ListGroup = React.createFactory ListGroup
ListGroupItem = React.createFactory ListGroupItem
Button = React.createFactory(require('./../../../../../react/common/KbcBootstrap').Button)

{div, span, h3, a} = React.DOM

module.exports = React.createClass
  displayName: 'ConfigSheetsPanel'
  mixins: [ImmutableRenderMixin]
  propTypes:
    isFileOwnerFn: React.PropTypes.func
    deselectSheetFn: React.PropTypes.func
    selectedSheets: React.PropTypes.object
    configSheets: React.PropTypes.object
    getPathFn: React.PropTypes.func

  render: ->
    #console.log @props.configSheets.toJS()
    div {},
      if @props.configSheets and @props.configSheets.count() > 0
        @_renderConfiguredSheets()
      @_renderSelectedSheets()

  _renderConfiguredSheets: ->
    div {},
      React.DOM.h2 className: '', 'Sheets Already Configured in Project'
      if @props.configSheets
        React.DOM.ul {},
          @props.configSheets.map((sheet) =>
            path = @props.getPathFn(sheet.get('googleId'))
            if not path
              path = ''
            else
              path = "#{path} / "
            fileTitle = sheet.get 'title'
            sheetTitle = sheet.get 'sheetTitle'
            React.DOM.li {},
              "#{path}#{fileTitle} / #{sheetTitle}").toArray()
      else
        div className: 'well', 'No sheets configured in project.'


  _renderSelectedSheets: ->
    #console.log @props.selectedSheets.toJS() if @props.selectedSheets
    div {},
      React.DOM.h2 className: '', 'Sheets To Be Added To Project'
      if @props.selectedSheets
        React.DOM.ul {},
          @_renderSelectedSheetsListGroup()
      else
        div className: 'well', 'No sheets selected.'

  _renderSelectedSheetsListGroup: ->
    listItems = @props.selectedSheets.map((sheets, fileId) =>
      path = @props.getPathFn(fileId)
      sheetItems = sheets.map((sheet, sheetId) =>
        fileTitle = sheet.getIn ['file','title']
        sheetTitle = sheet.get 'title'
        @_renderSheetGroupItem(path, fileTitle, sheetTitle, fileId, sheetId)
        ).toList()
      return sheetItems
    ).toList()
    listItems = listItems.flatten(true).toArray()



  _renderSheetGroupItem: (path, fileTitle, sheetTitle, fileId, sheetId) ->
    if not path
      path = ''
    else
      path = "#{path} / "
    React.DOM.li {},
      span {},
        "#{path}#{fileTitle} / #{sheetTitle} "
        span
          onClick: =>
            @props.deselectSheetFn(fileId, sheetId)
          className: 'kbc-icon-cup kbc-cursor-pointer', ''
