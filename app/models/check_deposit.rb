# coding: utf-8

# Le modèle CheckDeposit correspond à une remise de chèques. La logique est de 
# pouvoir préparer une remise de chèque à partir d'une banque (obligation du bank_account)
# et de remplir cette remise avec les checks (qui sont des chèques à encaisser, ce qui correspond
# au scope pending_checks des books.
# On peut ensuite ajouter ou retirer des chèques d'une remise. 
# Après dépôt à la banque, le relevé bancaire servira à valider la remise 
# qui ne peut plus être modifiée.
# Lors de l'ajout ou du retrait des chèques et au moment de la sauvegarde, 
# la champ bank_account_id des lignes est rempli avec le bank_account_id du check_deposit
class CheckDeposit < ActiveRecord::Base

  # La condition est mise ici pour que check_deposit.new soit associée d'emblée
  # à toutes les lignes qui correspondant aux chèques en attente d'encaissement
  # de l'organisme correspondant.
  belongs_to :bank_account
  has_many :checks, class_name: 'Line',
    dependent: :nullify,
    conditions: Proc.new {"credit > 0 and payment_mode='Chèque' and book_id IN (#{self.bids}) "},
    before_remove: :cant_if_pointed, #on ne peut retirer un chèque si la remise de chèque a été pointée avec le compte bancaire
    after_remove: :nil_bank_account_id,
    before_add: :cant_if_pointed do
                
  end

  def bids
    raise "Modèle CheckDeposit - Impossible de trouver les livres sans avoir l'organisme" if self.bank_account_id == nil
    bank_account.organism.income_books.all.collect {|b| b.id}.join(',')
  end

  # c'est la présence de bank_extract_line qui indique que le check_deposit à été pointé et ne peut plus être modifié
  has_one :bank_extract_line

  validates :bank_account_id, :deposit_date, :presence=>true
  validates :bank_account_id, :deposit_date, :cant_change=>true,  :if=> :has_bank_extract_line?
 
 
  # before_validation :not_empty # une remise chèque vide n'a pas de sens
  # sauf pour la reconstruction d'une compta complète

  after_save :update_checks, :if=> :bank_extract_line
  after_save :update_checks_with_bank_account_id

  before_destroy :cant_destroy_when_pointed

  # permet de trouver les check à encaisser
  def self.pending_checks(organism)
    organism.pending_checks
  end

  def target_checks
    if new_record?
      association(:checks).target
    else
      checks.all
    end
  end

  # TODO vérifier que cette idée est valable aussi pour edit
  # tank est le réservoir des chèques à remettre
  # il est calculé par checks dont on retire target_checks
  def tank_checks
    linked=target_checks
    if new_record?
      list = checks.all # requete de tous les chèques avec ID nul, credit, mode de paiement chèque et organism
    else
      list = bank_account.organism.pending_checks.all # check_deposit a une id donc il faut lire directement les pending_checks
    end
    list.reject {|check| linked.include? check }
  end

  # total checks fait la somme des chèques qui sont dans la cible de l'association.
  # cette approche est nécessaire car un module intégré donne un résultat vide
  def total_checks
    if new_record?
      return association(:checks).target.sum {|l|  l.credit}
    else
      checks.sum(:credit)
    end
  end

  # donne le total des chèques à encaisser pour cet organisme
  def self.total_to_pick(organism)
    pending_checks(organism).sum(:credit)
  end

  # donne le nombre total des chèques à encaisser pour un organisme
  def self.nb_to_pick(organism)
    pending_checks(organism).count
  end

  # pour remplir la remise de chèques avec la totalité des chèques disponibles
  # l'organisme peut être fourni en paramètre ou être déduit de self si bank_account est
  # informé
  def pick_all_checks(org =nil)
    org ||= bank_account.organism
    raise 'Undefined organism' unless org
    org.pending_checks.all.each {|l| checks << l}
  end

  def pick_date
    deposit_date ? (I18n::l deposit_date) : nil
  end

  def pick_date=(string)
    s = string.split('/')
    self.deposit_date = Date.civil(*s.reverse.map{|e| e.to_i})
  rescue ArgumentError
    self.errors[:deposit_date] << 'Date invalide'
    nil
  end

  # surcharge de restore qui est définie dans models/restore/restore_records.rb
  def self.restore(new_attributes)
    CheckDeposit.skip_callback(:create, :after, :update_checks)
    CheckDeposit.skip_callback(:create, :after, :update_checks_with_bank_account_id)
    super
  ensure
    CheckDeposit.set_callback(:create, :after, :update_checks)
    CheckDeposit.set_callback(:create, :after, :update_checks_with_bank_account_id)
  end


  private

  # appelé par before_save pour éviter les remises chèques vides
  def not_empty
    self.errors[:base] <<  'Il doit y avoir au moins un chèque dans une remise' if checks.empty?
  end


  # appelé par before_add et before_remove pour interdire l'ajout
  # ou le retrait de chèque sur une remise pointée
  def cant_if_pointed(line)
    if bank_extract_line
      logger.warn "Tentative d'ajouter ou de retirer une ligne à la remise de chèques #{id}, alors qu'elle est pointée sur la ligne de comte #{bank_extract_line.id}"
      raise 'Impossible de retirer un chèque d une remise pointée'
    end
  
  end

  
  # appelé par before_destroy pour interdire la destruction d'une remise de chèque pointée
  def cant_destroy_when_pointed
    if bank_extract_line
      logger.warn "Tentative de détruire la remise de chèques #{id}, alors qu'elle est pointée sur une ligne de comte #{bank_extract_line.id}"
      return false
    end
  end

  # mise à jour des lignes lorsque la remise chèques est pointée
  def update_checks
    if bank_extract_line
      logger.info "Mise à jour des lignes par before_save de check_deposit #{id} (méthode : update_checks_if_bank_extract_line"
      checks.each { |l| l.update_attributes(:bank_extract_id=>bank_extract_line.bank_extract.id)  }
    end
     
  end

  # met à jour les lignes avec le champ bank_account_id
  def update_checks_with_bank_account_id
    checks.each {|l| l.update_attribute(:bank_account_id, bank_account.id)}
  end


  # remet à nil le champ bank_account_id des lignes lorsqu'on les retire de la remise de chèques
  def nil_bank_account_id(line)
    line.update_attribute(:bank_account_id, nil)
  end

 
  def has_bank_extract_line?
    bank_extract_line ? true : false
  end
  
end
