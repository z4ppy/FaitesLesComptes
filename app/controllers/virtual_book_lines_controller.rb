# TODO actuellement, n'est prévu que pour un compte bancaire mais
# pourrait si besoin être utilisé pour une caisse.
# en distinguant si on a un params[cash_id] ou un params[:bank_account_id]

class VirtualBookLinesController < ApplicationController
  before_filter :fill_mois
  
  def index
    @bank_account=BankAccount.find(params[:bank_account_id])
    @virtual_book = @bank_account.virtual_book
    if params[:mois] == 'tous'
      @monthly_extract = Extract::BankAccount.new(@virtual_book, @period)
    else
      @monthly_extract = Extract::MonthlyInOut.new(@virtual_book, year:params[:an], month:params[:mois])
    end
    
    send_export_token # envoie un token pour l'affichage du message Juste un instant 
    # pour les exports
    respond_to do |format|
      format.html
      format.pdf {send_data @monthly_extract.to_pdf.render, :filename=>"#{@bank_account.nickname}_#{Time.now}.pdf" }
      format.csv { send_data @monthly_extract.to_csv(col_sep:"\t")  }  # pour éviter le problème des virgules
      format.xls { send_data @monthly_extract.to_xls(col_sep:"\t")  }
    end
  end

  
  protected
  # on surcharge fill_mois pour gérer le params[:mois] 'tous'
  def fill_mois
    if params[:mois] == 'tous'
      @mois = 'tous'
    else
      super
    end
  end
end