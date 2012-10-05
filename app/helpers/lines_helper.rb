# -*- encoding : utf-8 -*-


module LinesHelper
  
 

  # helper pour afficher les actions d'une cash line,
  #  En effet la modification (edit) d'une cash_line doit se faire par transfer
  #  si la ligne vient d'un virement
  # ou est en direct si c'est la ligne est une écriture saisie d'un livre de
  # recettes ou de dépenses.
  # TODO cette méthode pourrait être commune avec lines et être également partagée
  # avec bank_lines..
  def line_actions(line)
    html = ' '
      if line.owner_type == 'Transfer'
        html <<  icon_to('modifier.png', edit_transfer_path(line.owner_id)) if line.editable?
      else
        html <<  icon_to('modifier.png', edit_book_line_path(line.book_id, line)) if line.editable?
        html <<  icon_to('supprimer.png', [line.book,line], confirm: 'Etes vous sûr?', method: :delete) if line.editable?
      end


    content_tag :td, :class=>'icon' do
      html.html_safe
    end

  end



# Helper permettant de construire les options de counter_account pour le form
# La classe OptionsForAssociationSelect est dans lib
#
# Le deuxième argument indique si on veut une liste de compte pour une recette ou pour
# une dépense, la différence venant du traitement des chèques de recettes qui ne peuvent
# être mis que sur le compte chèque à l'encaissement
#
def options_for_cca(period, io = false)
 arr =  [OptionsForAssociationSelect.new('Banques', :list_bank_accounts, period),
    OptionsForAssociationSelect.new('Caisses',:list_cash_accounts, period)]
  if io == true
     arr << OptionsForAssociationSelect.new('Chèques à l\'encaissement', :rem_check_accounts, period)
  end
  arr
end



 



end
