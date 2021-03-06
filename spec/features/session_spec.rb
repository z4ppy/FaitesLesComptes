# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.configure do |c|
  #  c.filter = {:js=> true }
  #  c.filter = { :wip=>true}
  #  c.exclusion_filter = {:js=> true }
end

describe 'Session' do
  include OrganismFixtureBis

  context 'non logge' do

    it 'non loggé, renvoie sur sign_in'  do
      visit '/admin/organisms'
      page.find('h3').should have_content 'Entrée'
    end

    it 'on peut cliquer sur nouvel utilisateur' do
      visit '/'
      click_link("S'enregistrer comme nouvel utilisateur")
    end

  end

  context 'loggé'  do

    it 'sans organisme, renvoie sur la page de création', wip:true do
      create_only_user
      ApplicationController.any_instance.stub(:current_user).and_return @cu
      @cu.stub(:organisms).and_return []
      login_as(@cu, 'MonkeyMocha')
      current_url.should == new_admin_organism_url
    end

    it 'avec un organisme, renvoie sur le dashboard' do
      use_test_organism
      login_as(@cu, 'MonkeyMocha')
      current_url.should match(/http:\/\/www.example.com\/organisms\/\d*/)
    end

    it 'avec plusieures organisme, renvoie sur la liste' do
      use_test_organism
      # plutôt que de créer réellement plusieurs bases, on fait un stub
      ApplicationController.any_instance.stub(:current_user).and_return @cu
      # nécessaire pour l'affichage du menu des organismes
      @cu.stub(:organisms).and_return([@o, @o])
      login_as(@cu, 'MonkeyMocha')
      page.find('h3').should have_content 'Liste des organismes'
    end

  end

  describe 'création d un compte' do

    after(:each) do
      User.delete_all
    end

    it 'permet de créer un compte et renvoie sur la page merci de votre inscription', wip:true do
      visit '/users/sign_up'
      fill_in 'user_name', with:'test'
      fill_in 'user_email', :with=>'test@example.com'
      fill_in 'user_password', :with=>'testtest'
      fill_in 'user_password_confirmation', :with=>'testtest'
      click_button 'S\'inscrire'
      page.find('.alert').
        should have_content('Un message contenant un lien de confirmation a été envoyé')
    end

    it 'envoie un mail par UserObserver' do
      UserInscription.should_receive(:new_user_advice).and_return(double(Object, deliver:true ))
      visit '/users/sign_up'
      fill_in 'user_name', with:'test2'
      fill_in 'user_email', :with=>'test2@example.com'
      fill_in 'user_password', :with=>'testtest'
      fill_in 'user_password_confirmation', :with=>'testtest'
      click_button 'S\'inscrire'

    end

  end

  describe 'confirmation du compte' do

    it 'un nouvel utilisateur n est pas confirmé' do
      u = User.new(name:'essai', email:'bonjour@example.com')
      u.should_not be_confirmed
    end

    context 'avec un mauvais token' do

    it 'on est renvoyé sur la page de renvoi des instructions' do
      visit user_confirmation_path(confirmation_token: '1234567789')
      page.find('h3').should have_content 'Renvoyer les instructions de confirmation'
    end

    end

    context 'avec un bon token', wip:true  do

      before(:each) do
        create_only_tenant
        @cu =  User.new(name:'quidam',
           :email=>'bonjour@example.com', password:'bonjour1' )
        puts @cu.errors.messsages unless @cu.valid?
        @cu.save!
        @raw, @enc = Devise.token_generator.generate(User, :confirmation_token)
        @cu.update_attribute(:confirmation_token, @enc)

      end

      after(:each) do
        @cu.destroy if @cu
      end

      it 'l utilisteur est non confirmé' do
        @cu.should_not be_confirmed
      end

      it 'la confirmation marche' do
        User.confirm_by_token(@raw)
        @cu.reload.should be_confirmed
      end


      it 'un utilisateur non confirmé le devient avec un bon token' do
        # pending 'A revoir avec la nouvelle démarche de Devise'
        visit user_confirmation_path(confirmation_token: @raw)
        @cu.reload.should be_confirmed
      end

      it 'il est loggé' do
        visit user_confirmation_path(confirmation_token: @raw)
        page.find('.notice').should have_content 'Votre compte a été validé'
        page.find('h3').text.should have_content 'Entrée'
      end

    end


  end





end
