# Construit un nouveau Journal Général et l'affiche

class Compta::GeneralLedgersController < Compta::ApplicationController

  def new
    @general_ledger =  Compta::PdfGeneralLedger.new(@period)
    respond_to do |format|
        format.pdf  {send_data @general_ledger.render("lib/pdf_document/prawn_files/general_ledger.pdf.prawn"),
          filename:"Journal_General_#{@organism.title}.pdf"} 
    end
  end
  
end