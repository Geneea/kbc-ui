import React, {PropTypes} from 'react';
import ConfirmButtons from '../../../../../react/common/ConfirmButtons';
import CodeMirror from 'react-code-mirror';
import resolveHighlightMode from './resolveHighlightMode';

/* global require */
require('./queries.less');

export default React.createClass({
  propTypes: {
    script: PropTypes.string.isRequired,
    transformationType: PropTypes.string.isRequired,
    isSaving: PropTypes.bool.isRequired,
    onChange: PropTypes.func.isRequired,
    onCancel: PropTypes.func.isRequired,
    onSave: PropTypes.func.isRequired,
    isValid: PropTypes.bool.isRequired
  },

  render() {
    var codeMirrorParams = {
      value: this.props.script,
      theme: 'solarized',
      lineNumbers: true,
      mode: resolveHighlightMode('docker', this.props.transformationType),
      autofocus: true,
      lineWrapping: true,
      onChange: this.handleChange,
      readOnly: this.props.isSaving
    };
    if (this.props.transformationType === 'openrefine') {
      codeMirrorParams.lint = true;
      codeMirrorParams.gutters = ['CodeMirror-lint-markers'];
    }
    return (
      <div className="kbc-queries-edit">
        <div>
          {this.props.transformationType === 'r' ? (
            <div className="well">
              Read on <a href="https://sites.google.com/a/keboola.com/wiki/home/keboola-connection/user-space/transformations/-r">
                R limitations and best practices
              </a>.
            </div>
          ) : null}
          {this.props.transformationType === 'python' ? (
            <div className="well">
              Introducing <a href="https://sites.google.com/a/keboola.com/wiki/home/keboola-connection/user-space/transformations/python/01---introduction">
                Python in Keboola Connection
              </a>.
            </div>
          ) : null}
          {this.props.transformationType !== 'openrefine' ? (
            <div className="well">
              All source tables are stored in <code>/data/in/tables</code>
              (relative path <code>in/tables</code> , save all tables for output mapping to
              <code>/data/out/tables</code> (relative path <code>out/tables</code>).
            </div>
          ) : null}
          <div className="edit form-group kbc-queries-editor">
            <div className="text-right">
              <ConfirmButtons
                isSaving={this.props.isSaving}
                onSave={this.props.onSave}
                onCancel={this.props.onCancel}
                placement="right"
                isDisabled={!this.props.isValid}
                saveLabel="Save Script"
                />
            </div>
            <CodeMirror {...codeMirrorParams} />
          </div>
        </div>
      </div>
    );
  },

  handleChange(e) {
    this.props.onChange(e.target.value);
  }
});
