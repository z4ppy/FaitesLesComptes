# -*- encoding : utf-8 -*-

class BankExtractLine < ActiveRecord::Base
  belongs_to :bank_extract
  belongs_to :check_deposit
  belongs_to :line

  acts_as_list :scope => :bank_extract

#  default_scope order: :position  !! ne pas utiliser crée un bug dans la gestion des positions
# avec acts_as_list

  attr_reader :date, :payment, :narration, :debit, :credit, :blid

  after_save :link_to_source

  before_destroy :remove_link_to_source

  after_initialize :prepare_datas

  def prepare_datas
    if self.line_id != nil
      # TODO remplacer ces self.line par Line.find...
      l=self.line
      @date = l.line_date
      @debit= l.debit
      @credit=l.credit
      @payment=l.payment_mode
      @narration = l.narration
      @blid= "line_#{l.id}" # blid pour bank_line_id
    elsif self.check_deposit_id != nil
      cd=self.check_deposit
      @date=cd.deposit_date
      @debit=0
      @credit=cd.total
      @narration = 'remise de cheques'
      @payment = 'Chèques'
      @blid="check_deposit_#{cd.id}"
    end
    
  end

  # lock_line verrouille la ligne d'écriture. Ceci est appelé par bank_extract (after_save)
  # lorsque l'on verrouille le relevé
  # Seules les lignes d'écritures sont verrouillées (pas les remises de chèques) car
  # il s'agit seulement de se conformer à la législation qui impose de ne plus
  # pouvoir modifier des écritures après inscription au journal
  def lock_line
    if self.line_id && !self.line.locked
      self.line.update_attribute(:locked,true)
    end
  end
  
  private

  def link_to_source
    self.line.update_attribute(:bank_extract_id, self.bank_extract_id) if self.line_id
    self.check_deposit.update_attribute(:bank_extract_id, self.bank_extract_id) if self.check_deposit_id
  end

  def remove_link_to_source
    self.line.update_attribute(:bank_extract_id, nil) if self.line_id
    self.check_deposit.update_attribute(:bank_extract_id, nil) if self.check_deposit_id
  end

   
end
