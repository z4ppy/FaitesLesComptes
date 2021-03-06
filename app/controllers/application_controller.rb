# -*- encoding : utf-8 -*-

# TODO l'ancien session_controller (avant Devise) faisait un contrôle du navigateur
# et indiquait s'il y avait un problème

class ApplicationController < ActionController::Base
  include ModalsHelper
  protect_from_forgery

  before_action :authenticate_tenant!

  before_filter :find_organism, :current_period, :unless=>('milia_or_bottom_action?')

  helper_method :two_decimals, :virgule, :current_user, :current_period?, :abc # (pour ActiveRecord::Base.connection

  # construit un nom de fichier pour les export de csv ou de pdf avec
  # le titre de l'objet, le titre de l'organisme, et la date du jour, suivi de l'extension
  #
  # Les arguments sont un objet (qui devrait répondre à :title si possible) et
  # une extension sous forme de texte ou de symbole.
  def export_filename(obj, extension, titre=nil)
    if titre
      title = titre
    else
      title = obj.respond_to?(:title) ? obj.title : obj.class.name.split('::').last
    end
    "#{title} #{@organism.title} #{dashed_date(Date.today)}.#{extension.to_s}"
  end

  # met en forme une date au format dd-mmm-yyyy en retirant le point
  # par exemple 13-nov-2013 (et non 13-nov.-2016), ceci pour pouvoir
  # facilement inclure la date dans le nom d'un fichier
  def dashed_date(date)
    I18n.l(date, format:'%d-%b-%Y').gsub('.', '')
  end

  protected

  # Envoie un cookie si le format demandé est l'un des 3 (xls, csv, pdf)
  #
  # Cette méthode doit être appelée dans les actions qui permettent de l'export de données
  # sous l'un de ces 3 formats, si possible dans la partie respond_to.
  #
  # Elle marche en conjonction avec la méthode qui est dans export.js.coffee
  # pour permettre un retour à l'utilisateur en bolquant la page (avec la
  # mention Juste un instant) et en la débloquant à la réception du fichier.
  def send_export_token
    if request.format.in? ['application/xls', 'text/csv', 'application/pdf']
      cookies[:export_token] = { :value =>params[:token], :expires => Time.now + 1800 }
    end
  end


  private

  # bottom_action est une actions qui relève de bottom_controller, controller
  # appelé par les liens en bas de page (manuels, contact, ...)
  def milia_or_bottom_action?
    params[:controller] =~ /^milia/ ||
      params[:controller] =~ /^bottom/ ||
      params[:controller] =~ /^devise/ ||
      params[:controller] =~ /^home/
  end

  # on est dans une action du gem devise si on n'est pas loggé ou
  # si l'action n'est pas précisément de se déconnecter
  def milia_action?
    params[:controller] =~ /^Milia/
  end

  # Overwriting the sign_out redirect path method
  # def after_sign_out_path_for(user)
  #   devise_sessions_bye_url
  # end

  # Milia : Après l'authentification
  #
  # Lorsqu'il n'y a pas d'organisme, il faut afficher soit la vue
  # admin#index soit la vue organism selon qu'il y a plusieurs bases ou une seule
  #
#  def callback_authenticate_tenant
    # Rails.logger.debug 'Dans le callback after_authenticate_tenant'
    # session[:org_id] = nil
    # # case current_user.organisms.count
    # when 0
    #   flash[:notice]=premier_accueil(user)
    #   new_admin_organism_url
    # when 1
    #   @organism = current_user.organisms.first
    #   session[:org_id] = @organism.id
    #   organism_url(@organism)
    # else
    #   admin_organisms_url
    # end
#  end

# assigne la variable @organism ou renvoie vers l'index des organismes

  def find_organism
    logger.debug 'Dans find_organism de ApplicationController'
    logger.debug "Controller #{params[:controller]}"

    if session[:org_id]
      @organism = Organism.find_by_id(session[:org_id])
    else
      @organism = current_user.organisms.first
      session[:org_id] = @organism.id if @organism
    end
    unless @organism
      logger.debug "@organism non instancié"
      redirect_to new_admin_organism_url and return
    end
  end


  # A REVOIR
  # si pas de session, on prend le premier exercice non clos
  def current_period
    unless @organism
      logger.warn 'Appel de current_period sans @organism'
      return nil
    end
    if session[:period]
      @period = @organism.periods.find_by_id(session[:period])
    end
    # A ce stade @period peut être nil, on tente donc une autre approche
    unless @period
      @period = @organism.guess_period
      session[:period] = @period.id if @period
    end
    @period
  end



  def current_period?(p)
    p == current_period
  end

  # HELPER_METHODS

  # pour afficher une virgule à la place du point décimal.
  # TODO remplacer tous les recours à two_decimals par virgule chaque fois que possible.
  # TODO voir également à supprimer l'une de ces deux méthodes (la même existe dans ApplicationHelper'
  def two_decimals(montant)
    sprintf('%0.02f',montant)
  rescue
    '0.00'
  end

  # Pour transformer un montant selon le format numérique français avec deux décimales
  def virgule(montant)
    ActionController::Base.helpers.number_with_precision(montant, precision:2) rescue '0,00'
  end



  # Méthode à appeler dans les controller organisms pour
  # mettre à jour la session lorsqu'il y a un changement d'organisme
  # Récupère également les variables d'instance @organism et @period
  # si cela a du sens.
  # L'argument groom est un organisme.
  # TODO A déplacer dans le helper de Admin/Organism
  #
  def organism_has_changed?(groom = nil)
    change = false
    # premier cas : il y a un organisme et on vient de changer
    if groom && session[:org_id] != groom.id
      logger.debug "Passage à l'organisation #{groom.title}"
      session[:period] = nil
      session[:org_id]  = groom.id
      @organism  = groom
      if @organism
        @period = @organism.guess_period
        session[:period] = @period.id if @period
      end
      change =true
    end

    # deuxième cas : il n'y a pas ou plus de chambre
    if groom == nil #: on vient d'arriver ou de supprimer un organisme
      logger.debug "Aucun organismse sélectionné"
      session[:period] = nil
      session[:org_id] = nil
      change = true
    end

    # troisème cas : on reste dans la même pièce
    if groom && session[:org_id] == groom.id
      logger.debug "On reste à l'organisation #{groom.title}"
      @organism = groom
      logger.warn 'pas d\'organisme trouvé par has_changed_organism?' unless @organism
      current_period
      change = false
    end
    change
  end

  # fill_mois est utile pour tous les controller que l'on peut appeler avec une options qui peut être
  #   rien et dans ce cas, fill_mois trouve le mois le plus adapté
  #   mois:'tous' pour avoir tous les mois d'affichés
  #   mois:2, an:2013 pour demander un mois spécifique
  #
  # local_params doit renvoyer un hash avec les paramètres complémentaires nécessaires
  # essentiellement un id d'un objet, par exemple :cash_id=>@cash}
  #
  #
  # Ceci permet alors d'avoir un routage vers cash_cash_lines_path(@cash) en supposant
  # que l'on soit dans le controller cash_lines et avec l'action index
  #
  def fill_mois
    if params[:mois] && params[:an]
      @mois = params[:mois]
      @an = params[:an]
      @monthyear = @period.guess_month_from_params(month:@mois, year:@an)
    else
      @monthyear= @period.guess_month
      redirect_to url_for(mois:@monthyear.month, an:@monthyear.year) if params[:action]=='new'
      unless params[:mois] == 'tous'
        redirect_to url_for(mois:@monthyear.month, an:@monthyear.year, :format=>params[:format]) if (params[:action]=='index')
      end
    end
  end

  # remplit les champs written_by et user_ip pour savoir qui a créé ou modifié
  # en dernier une écriture.
  #
  # Appelé par in_out_writings_controller mais aussi par check_deposits, transfer,...
  #
  def fill_author(writing)
    writing.written_by = current_user.id
    writing.user_ip = current_user.current_sign_in_ip
  end

  # raccourci pour avoir la configuration
  #
  # abc pour ActiverecordBaseConnection_config
  def abc
    ActiveRecord::Base.connection_config
  end

  # à partir d'une nomenclature met en forme la liste éventuelle des erreurs
  # pour affichage dans un flash.
  #
  # utilisée par
  # - Admin#AccountsController#create pour créer le flash le messages qui est crée par le
  # AccountObserver lorsque la création d'un compte engendre une anomalie avec la nomenclature .
  # - Compta#SheetsController pour vérifier la nomenclature
  #
  def collect_errors(nomen)
    al = ''
    if nomen.errors.any?
      al = 'La nomenclature utilisée comprend des incohérences avec le plan de comptes. Les documents produits risquent d\'être faux.</br>'
      al += 'Liste des erreurs relevées : <ul>'
      nomen.errors.full_messages.each do |m|
        al += "<li>#{m}</li>"
      end
      al += '</ul>'

    end
    al.html_safe
  end

  # Message de bienvenue pour un utilisateur qui n'a encore créé aucun
  # organisme
    def premier_accueil(user)
      accueil = "Bienvenue #{user.name} !"
      accueil += "<br/>La première chose à faire est de créer un organisme "
      accueil.html_safe
    end



end
