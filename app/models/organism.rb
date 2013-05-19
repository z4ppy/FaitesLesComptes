# -*- encoding : utf-8 -*-

# La classe Organisme est quasiment la tête de toutes les classes du programme.
# Un organisme a des livres de recettes et de dépenses, mais aussi un livre d'OD et
# un d'A Nouveau. De même un organisme a un ou des comptes bancaires et une ou 
# des caisses.
# 
# Un organisme a également des archives pour faire les suavegardes et les restaurations.
# 
# Un organisme a également des exercices (Period), lesquels ont à leur tour des 
# comptes.
# 
# Les champs obligatoires sont le titre de l'organisme, la base de donnée associée, et 
# le statut (association ou entreprise).
# 
#  Précision sur la base de données : Pour faciliter les sauvegardes, chaque organisme
#  dispose de sa propre base de données (dont le nom doit bien sur être unique).
#  
#  Concrètement, ce sujet est traité par la classe Room, qui est celle qui effectue
#  la création de la base (et qui en vérifie l'unicité). La mention uniqueness => true
#  pour database_name est donc ici peu utile puisqu'il ne peut y avoir qu'un seul 
#  organisme par base.
#  
#  Le formulaire de création demande si on choisit le statut, lequel ne peut plus être
#  modifié ensuite : actuellement deux possibilités, association ou entreprise.
#  
#  La nomenclature, un Hash décrivant la construction des documents (Bilan, Compte
#  de Résultats) est également stockée à la création. Mais contrairement au statut, on 
#  peut modifier une nomenclature pour importer un autre type de fichier. Le but est 
#  de pouvoir adapter les éditions au cas où on ajouterait des comptes non prévus dans
#  la nomenclature fournie par défaut.
#
#  Le champ version enregistre la version qui a été utilisée pour la création de
#  l'organisme sur la base de la constante VERSION qui est dans le fichier
#  config/initializers/constant.rb
#
#  A terme cela permettra d'introduire un controller pour faire les migrations des bases qui
#  ne seraient pas à jour en terme de version.
#
#
class Organism < ActiveRecord::Base

  attr_accessible :title, :description, :database_name, :status

  has_one :nomenclature
  
  has_many :books, dependent: :destroy
  has_many :destinations, dependent: :destroy
  has_many :natures, through: :periods
  has_many :bank_accounts, dependent: :destroy
  has_many :bank_extracts, through: :bank_accounts
  has_many :bank_extract_lines, through: :bank_extracts
  has_many :writings, :through=>:books
  has_many :compta_lines, :through=>:writings
  has_many :check_deposits, through: :bank_accounts
  has_many :periods, dependent: :destroy
  has_many :cashes, dependent: :destroy
  has_many :cash_controls, through: :cashes
  has_many :income_books, dependent: :destroy
  has_many :outcome_books, dependent: :destroy
  has_one :an_book, dependent: :destroy
  has_many :od_books, dependent: :destroy
  has_many :virtual_books # les virtual_books ne sont pas persisted? donc inutile d'avoir un callback
  
  has_many :accounts, through: :periods
  has_many :archives,  dependent: :destroy
  has_many :pending_checks, through: :accounts # est utilisé pour l'affichage du message dans le dashboard
  has_many :transfers

  before_validation :fill_version
  after_create :create_default

  validates :title, presence: true, :format=>{with:NAME_REGEX}, :length=>{:within=>NAME_LENGTH_LIMITS}
  validates :description, :format=>{with:NAME_REGEX}, :maximum=>MAX_COMMENT_LENGTH, :allow_blank=>true
  validates :database_name, uniqueness:true, presence:true, :format=> {:with=>/\A[a-z][0-9a-z]*\z/, message:'format incorrect'}
  validates :status, presence:true, :inclusion=>{:in=>LIST_STATUS}

  

  


  
 

  # Retourne la dernière migration effectuée pour la base de données représentant cet organisme
  def self.migration_version
    ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations_paths).migrated.last
  end


  # retourne la collection de livres de Recettes et de Dépenses
  # ceux qui sont accessibles dans la partie saisie.
  #
  # S'appuie sur le scope in_outs de books
  def in_out_books
    books.in_outs
  end

  # créé un cash_book pour chacune des caisses
  def cash_books
   cashes.map do |c|
     vb = virtual_books.new
     vb.virtual = c
     vb
   end
  end

  # créé un virtual_book pour chacun des comptes bancaires
  def bank_books
    bank_accounts.map do |ba|
      vb = virtual_books.new
      vb.virtual = ba
      vb
    end
  end




 

  # retourne le nombre d'exercices ouverts de l'organisme
  def nb_open_periods
    periods.where('open = ?', true).count
  end

  def max_open_periods?
    nb_open_periods >=2 ? true :false
  end

  

  # indique si organisme peut écrire des lignes de comptes, ce qui exige qu'il y ait des livres
  # et aussi un compte bancaire ou une caisse
  # Utilisé par le partial _menu pour savoir s'il faut afficher la rubrique ecrire
  def can_write_line?
    if (self.income_books.any? || self.outcome_books.any?) && (self.bank_accounts.any? || self.cashes.any?)
      true
    else
      false
    end
  end

  # vérifie qu'il y a au moins un exercice pour lequel on peut faire les comptes
  def accountable?
    periods.select {|p| p.accountable? }.any?
  end
  
  # Renvoie la caisse principale (utilisée en priorité)
  # en l'occurence actuellement la première trouvée ou nil s'il n'y en a pas
  # Utilisé dans le controller line pour préremplir les select.
  # utilisé également dans le form pour afficher ou non le select cash
  def main_cash_id
    cashes.any?  ? cashes.first.id  :  nil
  end
  
  # renvoie le compte bancaire principal, en l'occurence, le premier
  def main_bank_id
    bank_accounts.any?  ? bank_accounts.first.id  :  nil
  end


  # TODO on peut faire beaucoup plus simple pour guess_period et find_period

  # find_period trouve l'exercice relatif à une date donnée
  # utilisé par exemple pour calculer le solde d'une caisse à une date donnée
  # par défaut la date est celle du jour
  def find_period(date=Date.today)
    period_array = periods.all.select {|p| p.start_date <= date && p.close_date >= date}
    if period_array.empty?
      Rails.logger.warn "organism#find_period a été appelée avec une date pour laquelle il n y a pas d'exercice : #{date} - Organism : #{self.inspect}"
      return nil if period_array.empty?
    end
    period_array.first
  end

  # trouve l'exercice le plus adapté à la date demandée
  # ne renvoie nil que s'il n'y a aucun exercice.
  #
  # Fonctionne en remettant la date dans les limites données par les exercices
  # et en appelant find_period.
  def guess_period(date = Date.today)
    return nil if periods.empty?
    ps = periods.order(:start_date)
    date = ps.first.start_date if date < ps.first.start_date
    date = ps.last.close_date if date > ps.last.close_date
    find_period(date)
  end

  # recherche la pièce où est logé Organism sur la base de la similitude des
  # champs database_name de ces deux tables
  def room
    look_for {Room.find_by_database_name(database_name)}
  end

  # TODO relève de la responsabilité de Room
  def full_name
    "#{Room.path_to_db}/#{database_name}.sqlite3"
  end
  
  # #look_for permet de chercher quelque chose dans la base principale
  # et de revenir dans la base de l'organisme.
  # Voir la méthode #room pour un exemple
  def look_for(&block)
    cc = ActiveRecord::Base.connection_config
    ActiveRecord::Base.establish_connection Rails.env
    yield
  ensure
    ActiveRecord::Base.establish_connection(cc)

  end

  # méthode produisant le document demandé par l'argument page, avec
  # comme argument optionnel l'exercie.
  #
  # Si period est absent, renvoie le dernier exercice
  def document(page, period = Period.last)
    Compta::Nomenclature.new(period).sheet(page)
  end

  
 
  
  private

  def fill_version
    self.version = VERSION
  end

  def fill_nomenclature 
    if status
      path = case Rails.env
      when 'test' then File.join Rails.root, 'spec', 'fixtures', status.downcase, 'good.yml'
      else
        File.join Rails.root, 'app', 'assets', 'parametres', status.downcase, 'nomenclature.yml'
      end
      yml = YAML::load_file(path)
      create_nomenclature(:actif=>yml[:actif], passif:yml[:passif], resultat:yml[:resultat], benevolat:yml[:benevolat])
    end
  end

  # crée les livres Recettes, Dépenses et OD
  # Crée également une banque et une caisse par défaut
  # et crée également la nomenclature
  def create_default
    # les 4 livres
    logger.debug 'Création des livres par défaut'
    income_books.create(abbreviation:'VE', title:'Recettes', description:'Recettes')
    logger.debug  'création livre recettes'
    outcome_books.create(abbreviation:'AC', title:'Dépenses', description:'Dépenses')
    logger.debug 'creation livre dépenses'
    od_books.create(abbreviation:'OD', :title=>'Opérations diverses', description:'Op° Diverses')
    logger.debug 'creation livre OD'
    create_an_book(abbreviation:'AN', :title=>'A nouveau', description:'A nouveau')

    cashes.create(name:'La Caisse')
    logger.debug 'creation de la caisse par défaut'
    bank_accounts.create(bank_name:'La Banque', number:'Le Numéro de Compte', nickname:'Compte courant')
    logger.debug 'creation la banque par défaut'

    fill_nomenclature
  end
  
end
