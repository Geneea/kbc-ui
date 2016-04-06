import React, {PropTypes} from 'react';
import Static from './ConfigurationStatic';
import Edit from './ConfigurationEdit';

/* global require */
require('codemirror/mode/javascript/javascript');

export default React.createClass({
  propTypes: {
    data: PropTypes.string.isRequired,
    isEditing: PropTypes.bool.isRequired,
    isSaving: PropTypes.bool.isRequired,
    onEditStart: PropTypes.func.isRequired,
    onEditCancel: PropTypes.func.isRequired,
    onEditChange: PropTypes.func.isRequired,
    onEditSubmit: PropTypes.func.isRequired,
    isValid: PropTypes.bool.isRequired,
    supportsEncryption: PropTypes.bool.isRequired,
    headerText: PropTypes.string,
    editLabel: PropTypes.string,
    saveLabel: PropTypes.string,
    help: PropTypes.node
  },

  getDefaultProps() {
    return {
      headerText: 'Configuration Data',
      help: null,
      editLabel: 'Edit configuration',
      saveLabel: 'Save configuration'
    };
  },

  render() {
    return (
      <div>
        <h2>{this.props.headerText}</h2>
        {this.props.help}
        {this.scripts()}
      </div>
    );
  },

  scripts() {
    if (this.props.isEditing) {
      return (
        <span>
          {
            this.props.supportsEncryption ?
              <p className="help-block small">Properties prefixed with <code>#</code> sign will be encrypted on save. Already encrypted strings will persist.</p>
              : null
          }
          { this.renderEditor() }
        </span>
      );
    } else {
      return (
        <Static
          data={this.props.data}
          onEditStart={this.props.onEditStart}
          editLabel={this.props.editLabel}
          />
      );
    }
  },

  renderEditor() {
    return (
      <Edit
        data={this.props.data}
        isSaving={this.props.isSaving}
        onSave={this.props.onEditSubmit}
        onChange={this.props.onEditChange}
        onCancel={this.props.onEditCancel}
        isValid={this.props.isValid}
        saveLabel={this.props.saveLabel}
        />
    );
  }
});
