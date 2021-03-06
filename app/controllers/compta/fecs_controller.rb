# coding: utf-8

# Controller permettant d'envoyer au format csv le fichier des écritures comptables
# telles que demandé par le Ministère des Finances 
class Compta::FecsController < Compta::ApplicationController

  def show
    @exfec = Extract::Fec.new(@period)
    respond_to do |format|
        format.csv { send_data @exfec.to_csv, filename:@exfec.fec_title }  
    end

  end

  
 
end