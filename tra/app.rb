class Tra < Padrino::Application
  register Padrino::Rendering
  register Padrino::Mailer
  register Padrino::Helpers

  enable :sessions

  ##
  # Application configuration options
  #
  # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
  # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
  # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
  # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
  # set :public_folder, "foo/bar" # Location for static assets (default root/public)
  # set :reload, false            # Reload application files (default in development)
  # set :default_builder, "foo"   # Set a custom form builder (default 'StandardFormBuilder')
  # set :locale_path, "bar"       # Set path for I18n translations (default your_app/locales)
  # disable :sessions             # Disabled sessions by default (enable if needed)
  # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
  # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
  #

  ##
  # You can configure for a specified environment like:
  #
  #   configure :development do
  #     set :foo, :bar
  #     disable :asset_stamp # no asset timestamping for dev
  #   end
  #

  ##
  # You can manage errors like:
  #
  #   error 404 do
  #     render 'errors/404'
  #   end
  #
  #   error 505 do
  #     render 'errors/505'
  #   end
  #
  include Log4r

  ########################################################################################################################
  ### Config Objects         #############################################################################################

  # This collection holds all data necessary to genericize the get,put,post logic for all data types.
  $REQUEST_CONFIGS = Hash.new
  $REQUEST_CONFIGS['project'] = { :table_name => 'project',
    :required_attributes => %w( name ),
    :allowed_subtypes => %w( runs )
  }
  $REQUEST_CONFIGS['run']     = { :table_name => 'run',
    :required_attributes => %w( project_id description submitted_by ),
    :allowed_subtypes => %w( results )
  }
  $REQUEST_CONFIGS['result']  = { :table_name => 'result',
    :required_attributes => %w( run_id test_case status ),
    :allowed_subtypes => %w()
  }
  # Provide plural names for data types.
  $REQUEST_CONFIGS['projects'] = $REQUEST_CONFIGS['project']
  $REQUEST_CONFIGS['runs']     = $REQUEST_CONFIGS['run']
  $REQUEST_CONFIGS['results']  = $REQUEST_CONFIGS['result']

  # Place holder classes for different exception types.
  class NotFoundException < Exception ; end
  class BadDataException < Exception ; end
  class BadURLException < Exception ; end 

  ########################################################################################################################
  ### Global Setup           #############################################################################################

  $db = SQLite3::Database.new( "./db/tra.db" )
  $db.results_as_hash = true

  $log = Logger.new( 'tra' )
  $log.outputters = FileOutputter.new( 'tra_log_file', :filename => './tra.log', :trunc => false )
  # $log.level = $VERBOSE ? Log4r::DEBUG : Log4r::WARN
  $log.level = Log4r::DEBUG

  # Catch Ctrl-C to exit cleanly.
  trap( "INT" ) do
  $log.fatal( "SIGINT caught. Exitting." )
    $db.close
  exit( 0 )
    end

  ########################################################################################################################
  ### Support Functionality  #############################################################################################

  # Return the name of the current method as a string.
    def this_method
    caller[0]=~/`(.*?)'/
    $1
    end

  # Standard output functionality.
  def output_json( data, status_code = 200 )
    [ status_code, { 'Content-Type' => 'application/json' }, data.to_json ]
  end

  def output_error( error, status_code )
    # Output a result ( unhappy case, exception raised ) built from the error information captured in the exception.

    result = {}
    result['inspect'] = error.inspect
    result['backtrace'] = error.backtrace

    $log.error( error.inspect )
    $log.debug( error.backtrace )

    output_json( result, status_code )
  end

  # This wraps execution to return an error to the user automatically without a lot of duplication.
  def with_protection( &block )

    $log.debug( '** Request Processing Initiated' )

    # Log EVERYTHING.
#    $log.debug( env.ai )

    # Prepare to run the given code block within a database transaction.
    result = nil

    # Retrieve request body.
    request.body.rewind
    request_body = request.body.read

    # Attempt to parse input body.
    input_data = nil
    input_data = JSON.parse( request_body ) unless request_body.empty?

    # Run the transaction, execute the block, and capture it's result.
    # NOTE: If no exception is raised, the transaction will close and call #commit automatically.
    # NOTE: If an exception is raised, the transaction will close and call #rollback automatically.
    $db.transaction do
      result = yield input_data
    end

    # Finally output the result ( happy case, no exceptions )
    unless result.empty?
      output_json( result )
    else
      [ 204, {}, '' ]
    end

    rescue BadURLException => e
      output_error( e, 404 )
    rescue BadDataException => e
      output_error( e, 400 )
    rescue NotFoundException => e
      output_error( e, 404 )
    rescue => e
      output_error( e, 500 )

    ensure
    $log.debug( '** Request Processing Complete' )
    end

  def ensure_id_numeric( id )
    raise BadDataException, "ID is non-numeric" unless id =~ /^\d+$/
  end

  # Ensure all provided keys are not empty strings. No point in empty strings here.
  def ensure_params_not_empty( input )
    input.each_pair do |key, value|
      raise BadDataException, "Empty/Nil value provided for input key: #{ key }" if input[key].nil? or ( input[key].respond_to?( :empty? ) and input[key].empty? )
    end
  end

  # Ensure the input hash contains elements with the given (required_attributes) keys.
  def ensure_params_exist( input, required_attributes )
    unless required_attributes.all? { |a| input.key?( a ) }
      raise BadDataException, "Missing required params. Expected list includes: #{ required_attributes.join( ', ' ) }"
    end
  end

  def ensure_record_exists( table_name, id )
    record_found = false

    qry = "SELECT id FROM #{ table_name } WHERE id=?"
    $log.debug "#{ this_method }: #{ qry }"
    $db.query( qry, [ id ] ) do |rst|
      rst.each { |row| record_found = true }
    end
    raise NotFoundException, "No #{ table_name } found with ID: #{ id }" unless record_found
  end

  def delete_item( table_name, id )

    ensure_record_exists( table_name, id )

    qry = "DELETE FROM #{ table_name } WHERE id=?"
    $log.debug "#{ this_method }: #{ qry }"
    $db.query( qry, [ id ] )

    # Nothing to return.
    nil
  end

  def get_item_list( table_name, required_attributes, where_clause = '', clause_params = [] )
    result = Array.new

    qry = "SELECT * FROM #{ table_name } #{ where_clause }"
    $log.debug "#{ this_method }: #{ qry }"
    $db.query( qry, clause_params ) do |rst|
      rst.each do |row| 
        row_hash = Hash.new
        row_hash['id'] = row['id']

        required_attributes.each do |a|
          row_hash[a] = row[a]
        end
      result << row_hash
      end
    end

    result
  end

  # Used by get_attributes. Please do not call this directly.
  def get_required_attributes( table_name, id, required_attributes )
    result = Hash.new

    qry = "SELECT * FROM #{ table_name } WHERE id=?"
    $log.debug "#{ this_method }: #{ qry }"
    # Insert the values of each required attribute into the result hash.
    $db.query( qry, [ id ] ) do |rst|
      rst.each do |row|
        required_attributes.each { |a| result[a] = row[a] }
      end
    end

    result
  end

  # Used by get_attributes. Please do not call this directly.
  def get_optional_attributes( table_name, id )
    result = Hash.new

    qry = "SELECT * FROM #{ table_name }_metadata WHERE #{ table_name }_id=?"
    $log.debug "#{ this_method }: #{ qry }"

    # Now insert the values of each optional attribute found in the project_metadata.
    $db.query( qry, [ id ] ) do |rst|
      rst.each do |row|
        key, value = row['name'], row['value']
        result[key] = value
      end
    end

    result
  end

  def get_attributes( table_name, id, required_attributes )
    ensure_record_exists( table_name, id )

    result = Hash.new
    result.merge! get_required_attributes( table_name, id, required_attributes )
    result.merge! get_optional_attributes( table_name, id )
    result
  end

  # NOTE: We can'd do assure params here because updates may or may not include all required fields 
  #       ( record required, not action required )
  def update_attributes( table_name, id, input_data, required_attributes )

    ensure_record_exists( table_name, id )
    ensure_params_not_empty( input_data )

    # Update any 'REQUIRED' attributes we found in the update body. 
    # NOTE: Required in this context are attributes that are part of the record and not metadata.)
    required_attributes.each do |a|
      if input_data.keys.include? a
        qry = "UPDATE #{ table_name } SET #{ a }=? WHERE id=?"
        $log.debug "#{ this_method }: #{ qry }"
        $db.query( qry, [ input_data[a], id ] )
      end
    end

    # Update any 'OPTIONAL' attributes we found in the update body.
    # NOTE: Optional in this context means attributes that are stored in the *_metadata table.
    metadata_keys = ( input_data.keys - required_attributes )
    metadata_keys.each do |k|
      qry = "INSERT OR REPLACE INTO #{ table_name }_metadata ( #{ table_name }_id, name, value ) VALUES ( ?, ?, ? )"
      $log.debug "#{ this_method }: #{ qry }"
      $db.query( qry, [ id, k, input_data[k] ] )
    end

    # Nothing to return.
    nil
  end

  def insert_attributes( table_name, input_data, required_attributes )

    # Make sure everything we must have exists ( or the INSERT will fail ).
    ensure_params_exist( input_data, required_attributes )
    ensure_params_not_empty( input_data )

    # Build a bit of metadata for the INSERT query. We need the field list, placeholding '?' for each field, 
    # and a copy of the value of each field in appropriate arrays.
    fields = required_attributes.select { |a| input_data.keys.include? a }
    place_holders = Array.new
    values = Array.new

    fields.each do |f|
      place_holders << '?'
      values << input_data[f]
    end

    qry = "INSERT INTO #{ table_name } ( #{ fields.join( ', ' ) } ) VALUES ( #{ place_holders.join( ', ' ) } )"
    $log.debug "#{ this_method }: #{ qry }"
    # Do INSERT & retrieve row_id.
    $db.query( qry, values )
    id = $db.last_insert_row_id

    # Insert *_metadata records an any additional parameters included in the create request body.
    metadata_keys = ( input_data.keys - required_attributes )
    metadata_keys.each do |k|
      qry = "INSERT INTO #{ table_name }_metadata ( #{ table_name }_id, name, value ) VALUES ( ?, ?, ? )"
      $log.debug "#{ this_method }: #{ qry }"
      $db.query( qry, [ id, k, input_data[k] ] )
    end

  # Finally, return the ID of the freshly created record.
  { "id" => id }
  end
end
