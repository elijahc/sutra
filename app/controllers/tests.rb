Sutra.controllers :tests do
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

  layout :default

  get :index do
    @tests = Test.all(:order => 'created_at desc')
    render 'tests/index'
  end

  get :new do
    @test = Test.new
    render 'tests/new'
  end

  post :create do
    @test = Test.new(params[:test])
    if @test.save
      flash[:notice] = 'Test was successfully created.'
      redirect url(:tests, :edit, :id => @test.id)
    else
      render 'tests/new'
    end
  end

  get :edit, :with => :id do

    ap.Test.find(params[:id])
  end

  put :update, :with => :id do
    @test = Test.find(params[:id])
    #do something here maybe. not sure if update is required
  end

end
