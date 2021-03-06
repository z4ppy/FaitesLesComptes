class ImportedBelsController < ApplicationController

  before_filter  :find_bank_account
  before_filter :correct_range_date, only: [:index]


  def index
    @imported_bels = @bank_account.imported_bels.order(:date, :position)
    set_border
    if @border_closed
      flash.now[:alert] = 'Aucune ligne ne peut être importée : extraits verrouillés
    ou absent; utiliser l\'icone +
      pour créer un nouvel extrait de compte si besoin'
    end
  end

  def update
    @imported_bel = ImportedBel.find params[:id]

    respond_to do |format|
      if @imported_bel.update_attributes(imported_bel_params)
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        format.json { respond_with_bip(@imported_bel) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@imported_bel) }
      end
    end

  end

  # action ayant pour but d'écrire une ligne en comptabilité ainsi que la
  # bank_extract_line qui lui correspond
  def write
    @imported_bel = ImportedBel.find params[:id]
    # récupérer les paramètres
    par = @imported_bel.to_write
    # TODO mettre ceci dans le modèle plutôt que le controller
    # TODO vérifier l'absence de problème avec un secteur commun pour les CE
    # créer soit le transfert soit le in_out_writing
    if @imported_bel.cat == 'T'
      book = @organism.od_books.first
      @writing = book.transfers.new(par)
    else
      book = @imported_bel.depense? ?
        @bank_account.sector.outcome_book : @bank_account.sector.income_book
      @writing = book.in_out_writings.new(par)
    end
    # rajouter les informations de user (id et ip)
    fill_author(@writing)
    # tenter de le sauver
    respond_to do |format|
      if @writing.save
        # on met à jour l'ibel
        @imported_bel.update_attribute(:writing_id, @writing.id)
        # on créé la bank_extract_line
        bex = @bank_account.bank_extracts.
          where('begin_date <= ? AND end_date >= ?',
          @imported_bel.date, @imported_bel.date).first
        bex.bank_extract_lines.create(compta_line_id:@writing.support_line.id)
        format.js
      else
        @message = "Erreur lors de la création de l'écriture : #{@writing.errors.full_messages.join('; ')}"
        format.js
      end
    end

  end

  def destroy
    ibel = ImportedBel.find_by_id(params[:id])
    @ibelid = params[:id] # on mémorise l'id pour pouvoir effacer en javascript
    @destruction = ibel.destroy if ibel
    respond_to do |format|
      format.html { redirect_to bank_account_imported_bels_url(@bank_account) }
      format.js
    end
  end

  def destroy_all
    @bank_account.imported_bels.delete_all
    redirect_to bank_account_imported_bels_url(@bank_account)
  end

  private

  def find_bank_account
    @bank_account = BankAccount.find(params[:bank_account_id])
  end

  # On ne peut écrire que dans les comptes bancaires de l'exercice
  # qui sont présents et non verrouillés
  def correct_range_date
    bexs = @bank_account.bank_extracts.period(@period).order(:begin_date)
    last_bex_date = bexs.last.end_date
    first_bex_date = bexs.unlocked.first.begin_date
    @correct_range_date = first_bex_date..last_bex_date
  rescue
    nil
  end

  # on peut importer à condition qu'il y ait au moins une écriture importable
  # crée l'instance @border_closed permettant de savoir ou non si on peut
  # importer au moins une écriture.
  def set_border
    @border_closed = false if @imported_bels.empty?
    @border_closed = @imported_bels.
      collect {|ibel| ibel.importable?(@correct_range_date)}.uniq == [false]
  end

  def imported_bel_params
    params.require(:imported_bel).permit(:date, :writing_date,
      :writing_date_picker, :narration, :debit, :credit, :position,
    :bank_account_id, :ref, :nature_id, :destination_id, :payment_mode, :cat)
  end

end
