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
  # c.filter = {wip:true}
end


describe Admin::MasksController do
  include SpecControllerHelper

  before(:each) do
    minimal_instances
    sign_in(@cu)
    @ma =  mock_model(Mask)
    @o.stub(:masks).and_return @a = double(Arel) 
  end
  # This should return the minimal set of attributes required to create a valid
  # Mask. As you add validations to Mask, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { { "title" => "MyString"} }

  
  describe "GET index" do
    it "assigns all admin_masks as @admin_masks" do
      @a.should_receive(:all).and_return [@ma]
      get :index, {:organism_id=>@o.to_param}, valid_session
      assigns(:masks).should eq([@ma])
    end
  end

  describe "GET show" do
    it "assigns the requested admin_mask as @admin_mask" do
      Mask.stub(:find).with(@ma.to_param).and_return @ma
      get :show, {:organism_id=>@o.to_param, :id => @ma.to_param}, valid_session
      assigns(:mask).should eq(@ma)
    end
  end

  describe "GET new" do
    it "assigns a new admin_mask as @admin_mask" do
      @a.should_receive(:new).and_return(@new_mask = mock_model(Mask).as_new_record)
      get :new, {:organism_id=>@o.to_param}, valid_session
      assigns(:mask).should be_a_new(Mask)
    end
  end

  describe "GET edit" do
    it "assigns the requested admin_mask as @admin_mask" do
      Mask.should_receive(:find).with(@ma.to_param).and_return @ma
      get :edit, {:organism_id=>@o.to_param, :id => @ma.to_param}, valid_session
      assigns(:mask).should eq(@ma)
    end
  end

  describe "POST create"  do
    describe "with valid params", wip:true do
      it "creates a new Mask" do
        @a.should_receive(:new).with(valid_attributes).and_return(@new_mask = mock_model(Mask))
        @new_mask.should_receive(:save).and_return true
        post :create, {:organism_id=>@o.to_param, :mask => valid_attributes}, valid_session
      end

      it "assigns a newly created mask as @mask" do
        @a.stub(:new).and_return(@new_mask = mock_model(Mask))
        @new_mask.stub(:save).and_return true
        post :create, {:organism_id=>@o.to_param, :mask => valid_attributes}, valid_session
        assigns(:mask).should be_a(Mask)
        assigns(:mask).should be_persisted
      end

      it "redirects to the created mask" do
        @a.stub(:new).and_return(@new_mask = mock_model(Mask))
        @new_mask.stub(:save).and_return true
        post :create, {:organism_id=>@o.to_param, :mask => valid_attributes}, valid_session
        response.should redirect_to admin_organism_mask_url(@o, @new_mask)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved admin_mask as @admin_mask" do
        @a.stub(:new).and_return(@new_mask = mock_model(Mask).as_new_record)
        @new_mask.stub(:save).and_return false
       
        post :create, {:organism_id=>@o.to_param, :mask => { "title" => "invalid value" }}, valid_session
        assigns(:mask).should be_a_new(Mask)
      end

      it "re-renders the 'new' template" do
        @a.stub(:new).and_return(@new_mask = mock_model(Cash).as_new_record)
        @new_mask.stub(:save).and_return false
        post :create, {:organism_id=>@o.to_param, :mask => { "title" => "invalid value" }}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested admin_mask" do
        Mask.should_receive(:find).with(@ma.to_param).and_return @ma
        @ma.stub(:update_attributes).with(valid_attributes).and_return true
        @ma.should_receive(:update_attributes).with({ "title" => "MyString" })
        put :update, {:organism_id=>@o.to_param, :id => @ma.to_param, :mask => { "title" => "MyString" }}, valid_session
      end

      it "assigns the requested admin_mask as @admin_mask" do
        Mask.stub(:find).with(@ma.to_param).and_return @ma
        @ma.stub(:update_attributes).with(valid_attributes).and_return true
        put :update, {:organism_id=>@o.to_param, :id => @ma.to_param, :mask => valid_attributes}, valid_session
        assigns(:mask).should eq(@ma)
      end

      it "redirects to the admin_mask" do
        Mask.stub(:find).with(@ma.to_param).and_return @ma
        @ma.stub(:update_attributes).with(valid_attributes).and_return true
        put :update, {:organism_id=>@o.to_param, :id => @ma.to_param, :mask => valid_attributes}, valid_session
        response.should redirect_to admin_organism_mask_url(@o, @ma)
      end
    end

    describe "with invalid params" do
      it "assigns the admin_mask as @admin_mask" do
        Mask.stub(:find).with(@ma.to_param).and_return @ma
        @ma.stub(:update_attributes).and_return(false)
        put :update, {:organism_id=>@o.to_param, :id => @ma.to_param, :mask => { "title" => "invalid value" }}, valid_session
        assigns(:mask).should eq(@ma)
      end

      it "re-renders the 'edit' template" do
        Mask.stub(:find).with(@ma.to_param).and_return @ma
        @ma.stub(:update_attributes).and_return(false)
        put :update, {:organism_id=>@o.to_param, :id => @ma.to_param, :mask => { "title" => "invalid value" }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested admin_mask" do
      Mask.should_receive(:find).with(@ma.to_param).and_return(@ma)
      @ma.should_receive(:destroy).and_return true
      delete :destroy, {:organism_id=>@o.to_param, :id => @ma.to_param}, valid_session
    end

    it "redirects to the admin_masks list" do
      Mask.stub(:find).with(@ma.to_param).and_return(@ma)
      delete :destroy, {:organism_id=>@o.to_param, :id => @ma.to_param}, valid_session
      response.should redirect_to(admin_organism_masks_url(@o))
    end
  end

end
