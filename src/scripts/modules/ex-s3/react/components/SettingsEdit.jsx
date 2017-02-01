import React, {PropTypes} from 'react';
import immutableMixin from '../../../../react/mixins/ImmutableRendererMixin';
import {Input} from 'react-bootstrap';
import Select from '../../../../react/common/Select';
import {List} from 'immutable';
import AutoSuggestWrapper from '../../../transformations/react/components/mapping/AutoSuggestWrapper';

export default React.createClass({
  mixins: [immutableMixin],

  propTypes: {
    s3Bucket: PropTypes.string.isRequired,
    s3Key: PropTypes.string.isRequired,
    wildcard: PropTypes.bool.isRequired,
    destination: PropTypes.string.isRequired,
    incremental: PropTypes.bool.isRequired,
    primaryKey: PropTypes.object.isRequired,

    defaultTable: PropTypes.string.isRequired,
    onChange: PropTypes.func.isRequired,
    tables: PropTypes.object.isRequired
  },

  onChangeDestination(value) {
    this.props.onChange('destination', value);

    // set primary key if table exists
    if (this.props.tables.has(value)) {
      this.props.onChange('primaryKey', this.props.tables.getIn([value, 'primaryKey']));
    } else {
      this.props.onChange('primaryKey', List());
    }
  },

  isExistingTable() {
    return this.props.tables.has(this.props.destination);
  },

  onChangeS3Bucket(e) {
    this.props.onChange('s3Bucket', e.target.value);
  },

  onChangeS3Key(e) {
    this.props.onChange('s3Key', e.target.value);
  },

  onChangeWildcard() {
    this.props.onChange('wildcard', !this.props.wildcard);
  },

  onChangeIncremental() {
    this.props.onChange('incremental', !this.props.incremental);
  },

  onChangePrimaryKey(value) {
    this.props.onChange('primaryKey', value);
  },

  getDestinationSuggestions() {
    const tables = this.props.tables.map(function(table) {
      return ({
        name: table.get('id')
      });
    });
    return function(value, callback) {
      const inputValue = value.trim().toLowerCase();
      const inputLength = inputValue.length;
      if (inputLength === 0) {
        return callback(null, []);
      }
      var suggestions = tables.filter(function(table) {
        return table.name.toLowerCase().indexOf(inputValue) >= 0;
      }).sortBy(function(table) {
        return table.name;
      }).slice(0, 7).map(function(table) {
        return table.name;
      }).toList().toJS();
      return callback(null, suggestions);
    };
  },

  primaryKeyHelp() {
    if (this.isExistingTable()) {
      return (<div className="help-block">Primary key of an existing table cannot be changed.</div>);
    }
    return (<div className="help-block">Primary key of the table. If primary key is set, updates can be done on table by selecting <strong>incremental loads</strong>. Primary key can consist of multiple columns.</div>);
  },

  primaryKeyPlaceholder() {
    if (this.isExistingTable()) {
      return 'Cannot add a column';
    }
    return 'Add a column';
  },

  createGetSuggestions() {
    const tables = this.props.tables.filter(function(item) {
      return item.get('id').substr(0, 3) === 'in.' || item.get('id').substr(0, 4) === 'out.';
    }).sortBy(function(item) {
      return item.get('id');
    }).map(function(item) {
      return item.get('id');
    }).toList();

    return function(input, callback) {
      var suggestions;
      suggestions = tables.filter(function(value) {
        return value.toLowerCase().indexOf(input.toLowerCase()) >= 0;
      }).sortBy(function(item) {
        return item;
      }).slice(0, 10).toList();
      return callback(null, suggestions.toJS());
    };
  },

  render() {
    return (
      <div className="row form-horizontal">
        <div className="col-md-12">
          <Input
            type="text"
            label="Bucket"
            labelClassName="col-xs-4"
            wrapperClassName="col-xs-8"
            value={this.props.s3Bucket}
            onChange={this.onChangeS3Bucket}
            placeholder="MyS3Bucket"
            />
        </div>
        <div className="col-md-12">
          <Input
            type="text"
            label="Key"
            labelClassName="col-xs-4"
            wrapperClassName="col-xs-8"
            value={this.props.s3Key}
            onChange={this.onChangeS3Key}
            placeholder="myfolder/myfile.csv"
            />
        </div>
        <div className="col-md-12">
          <div className="col-xs-8 col-xs-offset-4">
            <Input
              type="checkbox"
              label="Wildcard"
              labelClassName="col-xs-12"
              checked={this.props.wildcard}
              onChange={this.onChangeWildcard}
              help={(<span>If wildcard is turned on, all files in S3 with the defined prefix will be downloaded. Please note, that all files need to have the same header.</span>)}
              />
          </div>
        </div>
        <div className="col-md-12">
          <div className="form-group">
            <div className="col-xs-4 control-label">Destination</div>
            <div className="col-xs-8">
              <AutoSuggestWrapper
                suggestions={this.createGetSuggestions()}
                value={this.props.destination}
                onChange={this.onChangeDestination}
                placeholder="Table in Storage"
                id="destination"
                name="destination"
              />
              <span className="help-block">Table in Storage, where the CSV file will be imported. If the table or bucket does not exist, it will be created. Default <code>{this.props.defaultTable}</code></span>
            </div>
          </div>
        </div>
        <div className="col-md-12">
          <div className="col-xs-8 col-xs-offset-4">
            <Input
              type="checkbox"
              label="Incremental Load"
              labelClassName="col-xs-12"
              checked={this.props.incremental}
              onChange={this.onChangeIncremental}
              help={(<span>If incremental load is turned on, table will be updated instead of rewritten. Tables with primary key will update rows, tables without primary key will append rows.</span>)}
              />
          </div>
        </div>
        <div className="col-md-12">
          <div className="form-group">
            <div className="col-xs-4 control-label">Primary Key</div>
            <div className="col-xs-8">
              <Select
                name="primaryKey"
                value={this.props.primaryKey}
                multi={true}
                allowCreate={true}
                delimiter=","
                placeholder={this.primaryKeyPlaceholder()}
                emptyStrings={false}
                onChange={this.onChangePrimaryKey}
                disabled={this.isExistingTable()}
              />
              {this.primaryKeyHelp()}
            </div>
          </div>
        </div>
      </div>
    );
  }
});
