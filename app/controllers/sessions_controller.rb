# coding: utf-8


# TODO faire le session_controller_spec

class SessionsController < ApplicationController

  before_filter :check_browser
  skip_before_filter :log_in?, :only => [:new, :create]
  skip_before_filter :find_organism, :current_period


  def new
    reset_session
    @user = User.new
  end

  def create
    @user = User.find_by_name(params[:user][:name])
    if @user  # l'utilisateur est connu
      session[:user] = @user.id
      # réorientation automatique selon le nombre de rooms
      case @user.rooms.count
      when 0 then redirect_to new_admin_room_url and return
      when 1
          redirect_to room_url(@user.enter_first_room) and return
      else
          logger.debug 'passage par sessions_controller et plusieurs organismes'
          redirect_to admin_rooms_url and return
      end

    else
      link = %Q[<a href="#{new_admin_user_url(params[:user])}">Nouvel utilisateur</a>]
      flash[:alert] = "Cet utilisateur est inconnu. Si vous voulez vraiment créer un nouvel utilisateur, cliquez ici : #{link}. \n
      Sinon, saisissez le bon nom dans la zone ci-dessous".html_safe
      @user = User.new(params[:user])
      render 'new'
    end
  end

  def destroy
    session[:user] = session[:org_db] = session[:period]= nil
  end

  protected 

  def check_browser
   
    if browser.ie6? || browser.ie7? || browser.ie8? 
       flash[:alert] =  "Navigateur : #{browser.name}"
       render 'public/update_ie.html'
    end


  end

  


end