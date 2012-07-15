# -*- encoding : utf-8 -*-

class NaturesController < ApplicationController

  def stats
    @filter=params[:destination].to_i || 0
    @sn = Stats::StatsNatures.new(@period, @filter)
    respond_to do |format|
      format.html
      format.pdf
      format.csv { send_data @sn.to_csv(col_sep:"\t")  }  # \t pour éviter le problème des virgules
      format.xls { send_data @sn.to_xls(col_sep:"\t")  } 
    end
  end

 
 
 
end
