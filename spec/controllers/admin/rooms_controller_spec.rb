# -*- encoding : utf-8 -*-

require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass. 
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message. 

RSpec.configure do |c|
  #  c.filter = {:wip=> true }
end

describe Admin::RoomsController do
  include SpecControllerHelper
 
  def user_session
    {user:@cu.id}
  end

  before(:each) do
    minimal_instances
    # minimal instance donne @cu pour current_user et @r comme room
    @cu.stub('up_to_date?').and_return true
  end

 
  describe "GET index" do
    
    it "assigns all rooms as @rs" do
      @cu.should_receive(:rooms).and_return(@a = double(Arel, :map=>[]))

      get :index,{}, user_session
      assigns(:rooms).should eq(@a) 
    end

    it 'renders template index' do
      @cu.stub(:rooms).and_return(@a = double(Arel, :map=>[]))
      get :index,{}, user_session
      response.should render_template('index')
    end

    it 'si toutes les roome sont en phase n affiche pas de flash' do
      @cu.should_receive(:rooms).and_return([mock_model(Room, :relative_version=>:same_migration)])
      get :index,{}, user_session
      flash[:alert].should == nil
    end

    describe 'contrôle des flash' do
      
      before(:each) do
        @cu.stub(:rooms).and_return([mock_model(Room)])
        @cu.stub('up_to_date?').and_return false
      end

      it 'si une room est en retard affiche un flash' do
        @cu.stub(:status).and_return([:late_migration])
        get :index,{}, user_session
        flash[:alert].should == 'Une base au moins est en retard par rapport à la version de votre programme, migrer la base correspondante'
      end

      it 'si une room est en avance, affiche un flash' do
        @cu.stub(:status).and_return([:advance_migration])
        get :index,{}, user_session
        flash[:alert].should == 'Une base au moins est en avance par rapport à la version de votre programme, passer à la version adaptée'
      end

      it 'si une base n existe pas ' do
        @cu.stub(:status).and_return([:no_base])
        get :index,{}, user_session
        flash[:alert].should == 'Un fichier correspondant à une base n\'a pu être trouvée ; vous devriez effacer l\'enregistrement correspondant'
      end

    end
  end

  describe "GET show" do

    before(:each) do
      @cu.stub_chain(:rooms, :find).and_return @r
    end

    it "assigns the requested room as @r" do
      @cu.should_receive(:rooms).and_return(@a = double(Arel))
      @a.should_receive(:find).with(@r.to_param).and_return(@r)
      get :show, {:id => @r.to_param}, user_session
      assigns(:room).should eq(@r)
      
    end

    it 'redirige vers l organisme correspondant' do
      get :show, {:id => @r.to_param}, user_session
      response.should redirect_to(admin_organism_url(@o))
    end
  end

  describe 'POST migrate' do

    it 'migre la base demandée' do
      @cu.should_receive(:rooms).and_return(@a = double(Arel))
      @a.should_receive(:find).with(@r.to_param).and_return(@r)
      @r.should_receive(:migrate)
      post :migrate, {:id => @r.to_param}, user_session 
      flash[:notice].should == 'La base a été migrée et mise à jour'
      response.should redirect_to admin_organism_url
    end
  end

  describe 'GET new_archive' do
    it 'trouve l organisme et redirige' do
      @cu.should_receive(:rooms).and_return(@a = double(Arel))
      @a.should_receive(:find).with(@r.to_param).and_return(@r)
      get :new_archive, {:id => @r.to_param}, user_session
      response.should redirect_to new_admin_organism_archive_url(@o)
    end
  end

  #


  describe "DELETE destroy" do
    before(:each) do
      @cu.stub_chain(:rooms, :find).and_return(@r)
      @r.stub(:db_filename).and_return('assotest1.sqlite3')
      @r.stub(:absolute_db_name).and_return(File.join(Rails.root,'db', Rails.env, 'organisms', 'assotest1.sqlite3'))
      @r.stub(:organism).and_return(@organism=mock_model(Organism))
    end

    it 'renvoie vers rooms index' do
      @r.stub(:destroy).and_return true
      delete :destroy,{:id => @r.to_param}, user_session
      response.should redirect_to admin_rooms_url
    end

    it 'crée un flash sur suppression échoue' do
      @r.stub(:destroy).and_return false
      delete :destroy,{:id => @r.to_param}, user_session
      flash[:alert].should == "Une erreur s'est produite; la base assotest1.sqlite3 n'a pas été supprimée"
      response.should redirect_to admin_organism_url(@organism)
    end

    
  end

  describe 'GET new' do

    it 'rend le formulaire' do
      get :new, {}, valid_session
      response.should render_template :new
    end
  end





  describe 'POST create', wip:true do
    before(:each) do
      Organism.stub(:new).and_return(@o = mock_model(Organism, :full_name=>'bonjour', create_db:true, :save=>true))
      File.stub('exist?').and_return false
    end

    it 'si valid crée la pièce' do
      @cu.should_receive(:rooms).and_return(@a = double(Arel, :save=>true))
      @a.should_receive(:new).with(:database_name=>'test1').and_return @a
      @a.should_receive(:connect_to_organism).and_return true
      post :create, {'organism'=>{'name'=>'Bizarre', 'database_name'=>'test1'}}, valid_session
    end

    
    context 'quand room est correct' do

      before(:each) do
        @cu.stub_chain(:rooms, :new).and_return(@r = mock_model(Room, save:true, connect_to_organism:true).as_new_record)
      end

      context 'quand le fichier existe déjà' do

        it 'remplit un flash alert et rend le formulaire' do
          File.stub('exist?').and_return true
          post :create, {'organism'=>{'name'=>'Bizarre', 'database_name'=>'test1'}}, valid_session
          flash[:alert].should == 'Le fichier existe déja; Si vous voulez travailler avec ce fichier, vous devez restaurer l\'organism par le menu Restauration'
          response.should render_template :new
        end
      end


      it 'crée l organisme avec les paramètres' do
        Organism.should_receive(:new).with({'name'=>'Bizarre', 'database_name'=>'test1'}).and_return(stub_model(Organism))
        post :create, {'organism'=>{'name'=>'Bizarre', 'database_name'=>'test1'}}, valid_session
      end

      it 'sauve l organisme et la pièce' do
        @o.should_receive(:save).and_return true
        @r.should_receive(:save).and_return true
        post :create, {'organism'=>{'name'=>'Bizarre' , 'database_name'=>'test1'}}, valid_session
      end

      it 'redirige vers l action crétaion de period si sauvé' do
        @o.stub('valid?').and_return true
        @o.stub(:save).and_return true
        post :create, {'organism'=>{'name'=>'Bizarre', 'database_name'=>'test1'}}, valid_session
        response.should redirect_to new_admin_organism_period_url(@o)
      end


    end

    context 'quand organism est invalide' do

      it 'renvoie un flash alert et redirige vers new' do
        @o.should_receive(:valid?).and_return false
        post :create, {'organism'=>{'name'=>'Bizarre' , 'database_name'=>'test1'}}, valid_session
        response.should render_template :new
        flash[:alert].should == 'Impossible de créer l\'organisme'
      end
    end

    context 'quand room est incorrect' do

      before(:each) do
        @cu.stub_chain(:rooms, :new).and_return(@r = mock_model(Room, save:false).as_new_record) 
      end


      it 'renvoie le formulaire ' do
        post :create, {'organism'=>{'name'=>'Bizarre', 'database_name'=>'test1'}}, valid_session
        response.should render_template :new
      end

    end

  end


end
