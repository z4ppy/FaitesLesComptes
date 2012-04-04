class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :find_organism, :current_period

  helper_method :two_decimals, :picker_to_date

  private

  def find_organism
    @organism=Organism.find(params[:organism_id]) if params[:organism_id]
  end

  # HELPER_METHODS

  def current_period
    if @organism
      pid = session[:period] ||= (@organism.periods.order(:start_date).last.id if (@organism && @organism.periods.any?))
      @period= Period.find(pid) if pid
    end
  end
 
  def two_decimals(montant)
    sprintf('%0.02f',montant)
  rescue
    '0.00'
  end

  # picker_to_date est utilisée pour transformer le retour du widget
  # date picker qui est sous la forme "dd/mm/aaaa".Alors que Date.civil
  # demande aaaa,mm,dd.
  # On utilise donc split puis reverse puis to_i (et l'opérateur splat : * ) pour
  # transmettre ces arguments
  # La fonctin retourne un objet Date ou nil si la string ne permet pas de former
  # une date valide
  #

  # TODO mettre dans un before save
  def picker_to_date(string)
    s = string.split('/')
    Date.civil(*s.reverse.map{|e| e.to_i})
  rescue
    @period.guess_date
  end

  

  

end
