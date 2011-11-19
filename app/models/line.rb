# -*- encoding : utf-8 -*-

class Line < ActiveRecord::Base
  belongs_to :listing
  belongs_to :destination
  belongs_to :nature

  validates :debit, :credit, numericality: true

  default_scope order: 'line_date ASC'

  scope :mois, lambda { |date| where('line_date >= ? AND line_date <= ?', date.beginning_of_month, date.end_of_month) }
 

  # before_validation :default_debit_credit
#
#
#
#  private
#
#  def default_debit_credit
#    # ici il faudrait plutôt mettre à zero tout ce qui n'est pas un nombre
#    debit ||= 0.0
#    credit ||= 0.0
#  end

  
end
