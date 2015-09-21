# -*- encoding : utf-8 -*-

require 'spec_helper'
require 'support/spec_controller_helper'
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

describe Admin::AccountsController do
  include SpecControllerHelper

  RSpec.configure do |config|
#    config.filter =  {wip:true}
  end

  let(:a1) {mock_model(Account, long_name:'999 compte de test')}


  def valid_attributes
    {"title"=>'CrediX', "number"=>'5555', "period_id"=>@p.to_param}
  end

  before(:each) do
    minimal_instances
    @p.stub(:accounts).and_return @a = double(Arel)
  end

  describe "GET index", wip:true do

    it 'demande à Account sa list de compte pour la périod' do
      Account.should_receive(:list_for).with(@p).and_return [1,2]
      get :index, {:period_id=>@p.to_param}, valid_session
    end

    it "et l'assigne à @accounts" do
      Account.stub(:list_for).and_return [1,2]
      get :index, {:period_id=>@p.to_param}, valid_session
      assigns(:accounts).should == [1,2]
    end
  end



  describe "GET new" do
    it "assigns a new account as @account" do
      @a.should_receive(:new).and_return mock_model(Account).as_new_record
      get :new,  {:period_id=>@p.to_param}, valid_session
      assigns(:account).should be_a_new(Account)
    end
  end

  describe "GET edit" do
    it "assigns the requested account as @account" do
      Account.stub(:find).with(a1.to_param).and_return(a1)
      get :edit,{ period_id:@p.to_param, :id => a1.to_param}, valid_session
      assigns(:account).should == a1
    end
  end

  describe 'toggle_used permet de changer le champ used' do

    it 'cherche le compte, toggle used et l assigne' do
      @a.should_receive(:find).with(a1.to_param).and_return(a1)
      a1.stub(:toggle).with(:used).and_return a1
      a1.stub(:save).and_return true
      post :toggle_used, {:period_id=>@p.to_param,  :id => a1.to_param, format: :js}, valid_session
      assigns(:account).should == a1
    end

    it 'si ne la trouve pas crée un flash alert' do
      @a.stub(:find).with(a1.to_param).and_return(nil)
      post :toggle_used, {:period_id=>@p.to_param,  :id => a1.to_param, format: :js}, valid_session
      flash[:alert].should == 'Impossible de trouver le compte demandé'
    end


  end

  describe "POST create" do
    context 'with valid nomenclature' do
      before(:each) do
        @o.stub(:nomenclature).and_return(mock_model(Nomenclature, 'coherent?'=>true))
      end

      describe "with valid params" do
        it "creates a new account" do
          @a.should_receive(:new).with(valid_attributes).and_return(@b = mock_model(Account).as_new_record)
          @b.stub(:save)
          post :create, {:period_id=>@p.to_param, :account => valid_attributes}, valid_session
        end

        it "assigns a newly created account as @account" do
          @a.stub(:new).and_return(a1)
          a1.stub(:save).and_return(true)
          post :create, {:period_id=>@p.to_param, :account => valid_attributes}, valid_session
          assigns(:account).should == a1

        end

        it "redirects to the created account" do
          @a.stub(:new).and_return(a1)
          a1.stub(:save).and_return(true)
          post :create, {:period_id=>@p.to_param, :account => valid_attributes}, valid_session
          response.should redirect_to(admin_period_accounts_url(@p))
        end
      end

      describe "with invalid params" do

        it "re-renders the 'new' template" do
          @a.stub(:new).and_return(a1)
          a1.stub(:save).and_return(false)
          post :create, {:period_id=>@p.to_param, :account => valid_attributes}, valid_session
          response.should render_template("new")
        end
      end

    end

    context 'with invalid nomenclature' do
      before(:each) do
        @o.stub(:nomenclature).and_return(@n = Nomenclature.new)
        @n.stub('coherent?').and_return false
        @a.stub(:new).and_return(a1)
        a1.stub(:save).and_return(true)

        controller.stub(:collect_errors).and_return 'liste des erreurs'
        post :create, {:period_id=>@p.to_param, :account => valid_attributes}, valid_session
      end
      it 'affiche un flash alert' do
        flash[:alert].should == 'liste des erreurs'
      end

    end

    describe 'collect_errors' do

      before(:each) do
        @o.stub(:nomenclature).and_return(@n = Nomenclature.new)
        @n.stub('coherent?').and_return false
        @n.errors.add(:actif, 'Manque le compte 2124 pour l\'exercice 2013')
        @n.errors.add(:passif, 'Manque le compte 124 pour l\'exercice 2013')
        @a.stub(:new).and_return(a1)
        a1.stub(:save).and_return(true)


        post :create, {:period_id=>@p.to_param, :account => valid_attributes}, valid_session
      end
      it 'liste les erreurs' do

        flash[:alert].should == %Q(La nomenclature utilisée comprend des incohérences avec le plan de comptes. Les documents produits risquent d'être faux.</br>\
Liste des erreurs relevées : <ul>\
<li>Actif Manque le compte 2124 pour l'exercice 2013</li>\
<li>Passif Manque le compte 124 pour l'exercice 2013</li>\
</ul>)
      end


    end



  end


  describe "PUT update" do
    context 'toutes les natures sont reliées' do
      before(:each) do
        @p.stub(:all_natures_linked_to_account?).and_return true
      end


      describe "with valid params" do


        it "updates the requested account" do
          Account.should_receive(:find).with(a1.to_param).and_return(a1)
          a1.should_receive(:update_attributes).with({'title' => 'test'}).and_return(true)
          put :update,{:period_id=>@p.to_param,
            :id => a1.to_param, :account => {'title' => 'test'}}, valid_session
        end

        it "assigns the requested account as @account" do
          Account.stub(:find).with(a1.to_param).and_return(a1)
          a1.stub(:update_attributes).and_return(true)
          put :update,{:period_id=>@p.to_param,
            :id => a1.to_param, :account => {'title' => 'test'}}, valid_session
          assigns(:account).should eq(a1)
        end

        it "redirects to the account" do
          Account.stub(:find).with(a1.to_param).and_return(a1)
          a1.stub(:update_attributes).and_return(true)
          put :update,{:period_id=>@p.to_param,
            :id => a1.to_param, :account => {'title' => 'test'}}, valid_session
          response.should redirect_to(admin_period_accounts_url(@p))
        end
      end

      describe "with invalid params" do
        it "assigns the account as @account" do
          Account.stub(:find).with(a1.to_param).and_return(a1)
          a1.stub(:update_attributes).and_return(false)
          put :update,{:period_id=>@p.to_param,
            :id => a1.to_param, :account => {'title' => 'test'}}, valid_session
          assigns(:account).should eq(a1)
        end

        it "re-renders the 'edit' template" do
          Account.stub(:find).with(a1.to_param).and_return(a1)
          a1.stub(:update_attributes).and_return(false)
          put :update,{:period_id=>@p.to_param,
            :id => a1.to_param, :account => {'title' => 'test'}}, valid_session
          response.should render_template("edit")
        end
      end
    end


  end



  describe "DELETE destroy" do
    it "destroys the requested account" do
      Account.should_receive(:find).with(a1.to_param).and_return(a1)
      delete :destroy, {:period_id=>@p.to_param,
        :id => a1.to_param}, valid_session

    end

    it "redirects to the accounts list" do
      Account.should_receive(:find).with(a1.id.to_s).and_return(a1)
      delete :destroy, {:period_id=>@p.to_param,
        :id => a1.id.to_s}, valid_session
      response.should redirect_to(admin_period_accounts_url(@p))
    end

    it 'en cas d echec crée un flash' do
      Account.should_receive(:find).with(a1.id.to_s).and_return(a1)
      a1.stub(:errors).and_return(double(ActiveModel::Errors, :full_messages=>['une erreur', 'deux erreurs']))
      a1.stub(:destroy).and_return false
      delete :destroy, {:period_id=>@p.to_param,
        :id => a1.id.to_s}, valid_session
      flash[:alert].should  match 'une erreur; deux erreurs'
    end
  end

end
