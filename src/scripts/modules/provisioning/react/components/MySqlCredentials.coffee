React = require 'react'

Protected = React.createFactory(require('kbc-react-components').Protected)
Clipboard = React.createFactory(require('../../../../react/common/Clipboard').default)
Loader = React.createFactory(require('kbc-react-components').Loader)

{span, div, strong, small, a} = React.DOM

MySqlCredentials = React.createClass
  displayName: 'MySqlCredentials'
  propTypes:
    credentials: React.PropTypes.object
    isCreating: React.PropTypes.bool
    hideClipboard: React.PropTypes.bool

  getDefaultProps: ->
    hideClipboard: false

  render: ->
    div {},
      if @props.isCreating
        span {},
          Loader()
          ' Creating sandbox'
      else
        if @props.credentials.get "id"
          @_renderCredentials()

        else
          'Sandbox not running'

  _renderCredentials: ->
    span {},
      div {className: 'row'},
        div className: 'col-md-12',
          small className: 'help-text',
            'Use these credentials to connect to the sandbox with your \
            favourite SQL client (we like '
            a {href: 'http://www.sequelpro.com/download', target: '_blank'},
              'Sequel Pro'
            '). You can also use the Adminer web application provided by Keboola (click on Connect).'
      div {className: 'row'},
        span {className: 'col-md-3'}, 'Host'
        strong {className: 'col-md-9'},
          @props.credentials.get "hostname"
          @_renderClipboard Clipboard text: @props.credentials.get "hostname"
      div {className: 'row'},
        span {className: 'col-md-3'}, 'Port'
        strong {className: 'col-md-9'},
          '3306'
          @_renderClipboard Clipboard text: '3306'
      div {className: 'row'},
        span {className: 'col-md-3'}, 'User'
        strong {className: 'col-md-9'},
          @props.credentials.get "user"
          @_renderClipboard Clipboard text: @props.credentials.get "user"
      div {className: 'row'},
        span {className: 'col-md-3'}, 'Password'
        strong {className: 'col-md-9'},
          Protected {},
            @props.credentials.get "password"
          @_renderClipboard Clipboard text: @props.credentials.get "password"
      div {className: 'row'},
        span {className: 'col-md-3'}, 'Database'
        strong {className: 'col-md-9'},
          @props.credentials.get "db"
          @_renderClipboard Clipboard text: @props.credentials.get "db"

  _renderClipboard: (cpElement) ->
    if not @props.hideClipboard
      return cpElement
    else
      return null

module.exports = MySqlCredentials
