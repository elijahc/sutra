Tra.controllers  do
  # get :index, :map => "/foo/bar" do
  #   session[:foo] = "bar"
  #   render 'index'
  # end

  # get :sample, :map => "/sample/url", :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   "Maps to url '/foo/#{params[:id]}'"
  # end

  # get "/example" do
  #   "Hello world!"
  # end

  post "/clear" do
    with_protection do |input_data|
      qry = 'DELETE FROM project;'
      $log.debug "#{ this_method }: #{ qry }"
      $db.query( qry, [] )
    end

    nil
  end

  # List all items of a given type. ie. /project(s) /run(s) /result(s)
  get :index, :map => '/:type' do |type|
    with_protection do |input_data|
      cfg = REQUEST_CONFIGS[type]
      raise BadURLException, "Invalid type requested: #{ type }" if cfg.nil?

      get_item_list( cfg[:table_name], cfg[:required_attributes] )
    end
  end

  # Get a specific item. ie. /project(s)/1
  get :index, :map => '/:type/:id' do |type, id|
    with_protection do |input_data|
      ensure_id_numeric( id )

      cfg = REQUEST_CONFIGS[type]
      raise BadURLException, "Invalid type requested: #{ type }" if cfg.nil?

      get_attributes( cfg[:table_name], id, cfg[:required_attributes] )
    end
  end

  # Update a specific item
  put :index, :map => '/:type/:id' do |type, id|
    with_protection do |input_data|
      ensure_id_numeric( id )

      cfg = REQUEST_CONFIGS[type]
      raise BadURLException, "Invalid type requested: #{ type }" if cfg.nil?

      update_attributes( cfg[:table_name], id, input_data, cfg[:required_attributes] )
    end
  end

  # delete a specific item ( and all sub data ) 
  # NOTE: this method also, should only exist in test environment.
  delete :index, :map => '/:type/:id' do |type, id|
    with_protection do |input_data|
      ensure_id_numeric( id )

      cfg = REQUEST_CONFIGS[type]
      raise BadURLException, "Invalid type requested: #{ type }" if cfg.nil?

      delete_item( cfg[:table_name], id )
    end
  end

  # Create an item.
  post :index, :map => '/:type/create' do |type|
    with_protection do |input_data|
      cfg = REQUEST_CONFIGS[type]
      raise BadURLException, "Invalid type requested: #{ type }" if cfg.nil?

      insert_attributes( cfg[:table_name], input_data, cfg[:required_attributes] )
    end
  end

  ### Misc other UI for searching/listing.
  ## NOTE ######## PLEASE PLACE SPECIAL SEARCH FUNCTIONS ABOVE THE GENERIC FUNCTION OTHERWISE THEY WILL NOT GET USED.


  #  GENERIC SEARCH FUNCTION: List subtype for type. ie. /project(s)/1/run(s)
  get :index, :map => '/:type/:id/:subtype' do |type, id, subtype|
    with_protection do |input_data|
      ensure_id_numeric( id )

      cfg = REQUEST_CONFIGS[type]
      raise BadURLException, "Invalid type requested: #{ type }" if cfg.nil?
      raise BadURLException, "Invalid subtype requested: #{ subtype } for #{ type }" unless cfg[:allowed_subtypes].include? subtype

      sub_cfg = REQUEST_CONFIGS[subtype]
      raise BadURLException, "Invalid subtype requested: #{ subtype } }" if sub_cfg.nil?

      ensure_record_exists( cfg[:table_name], id )
      get_item_list( sub_cfg[:table_name], sub_cfg[:required_attributes], "WHERE #{ cfg[:table_name] }_id=?", [ id ] )
    end
  end
end
