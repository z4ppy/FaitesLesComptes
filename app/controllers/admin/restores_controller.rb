# coding: utf-8

# La classe restore fait les différentes opérations de restauration d'un fichier
# new permet d'afficher la vue qui demande quel fichier importer
# puis create charge le fichier et crée la base correspondante

class Admin::RestoresController < Admin::ApplicationController
  
  class RestoreError < StandardError; end

  skip_before_filter :find_organism, :current_period
  before_filter :db_format

  def new
    
  end

  # create 
  #  Vérifie que la base de données n'existe pas.
  # Trois cas de figure : soit elle existe et appartient au user
  # soit elle existe et n'appartient pas au user
  # soit elle n'existe pas.
  # Dans tous les cas, on demande une confirmation
  #
  # TODO affiner cette question en traitant le cas où on importe une
  # base antérieure et une base postérieure à la version actuelle.
  def create

    uploaded_io = params[:file_upload]
    Rails.cache.clear('version_update')

    begin

      # TODO utiliser des validations
      
      # vérification que l'extension est bien la bonne
      extension = File.extname(uploaded_io.original_filename)
      if  ".#{@db_extension}" != extension
        raise RestoreError, "L'extension #{extension} du fichier ne correspond pas aux bases gérées par l'application : .#{@db_extension}"
      end

      # la pièce ne doit pas déjà appartenir à un autre
      @room = Room.find_by_database_name(params[:database_name]) # le nom de la base existe
      if @room != nil && @room.user != current_user
        raise RestoreError, 'Ce nom de base est déjà pris et ne vous appartient pas'
      end
      
      # si la pièce n'existe pas on doit la créer
      if @room == nil
        @room = current_user.rooms.new(database_name:params[:database_name])
        raise RestoreError, 'Nom de base non valide : impossible de créer la base' unless @room.valid?
      end

      File.open(file_path, 'wb') do |file|
        file.write(uploaded_io.read)
      end

      @room.save!
      # on vérifie la base
      unless @room.check_db
        raise RestoreError, 'Le contrôle du fichier par SQlite renvoie une erreur'
      end

      # On indique à l'organisme quelle base il utilise (puisqu'on peut faire des copies)
      Organism.first.update_attribute(:database_name, params[:database_name])
      # tout s'est bien passé on sauve la nouvelle pièce
      use_main_connection
     
      if @room.relative_version == :same_migration
        flash[:notice] = "Le fichier a été chargé et peut servir de base de données"
      end
    redirect_to admin_rooms_url
    rescue RestoreError => e
      flash[:alert] = e.message 
      render 'new'
    end
  end


  protected

  # retourne le nom de l'adapter de l'application, par exemple sqlite3.
  def db_format
    @db_extension = Rails.application.config.database_configuration[Rails.env]['adapter']
  end

  def file_path
    if Rails.env == 'test'
      return Rails.root.join('db', 'test', 'organisms', "#{params[:database_name]}.sqlite3")
    elsif ENV['OCRA_EXECUTABLE']
      return File.expand_path("../db/#{Rails.env}/organisms/#{params[:database_name]}.sqlite3", ENV['OCRA_EXECUTABLE'])
    else
      return Rails.root.join('..', 'db', Rails.env, 'organisms', "#{params[:database_name]}.sqlite3")
    end
  end
 

end