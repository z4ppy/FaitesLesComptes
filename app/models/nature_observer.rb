# coding: utf-8

#NatureObserver sert à mettre à jour les lignes de la comptabilité lorsque
# la nature est rattachée à un compte.
# Il est en effet plus que probable que dans la majeure partie des cas, ce rattachement
# sera souvent fait à postériori.
class NatureObserver < ActiveRecord::Observer

  # si on rattache nature à un compte, les lignes qui ont cette nature
  # doivent voir leur champ account_id mis à jour.
  def after_save(nature)
      if nature.account_id_changed?
        Rails.logger.info 'Mise à jour du champ account_id des lignes suite à modification de nature'
       Rails.logger.debug "Nombre de lignes modifiées : #{Line.where('nature_id = ?', nature.id).count}"
        Line.where('nature_id = ?', nature.id).each do |l|
 
          l.update_attributes(:account_id=>nature.account_id)
   
        end

      end
  end

end