# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

RSpec.configure do |c|
  # c.filter = {:wip=>true}
end


describe Compta::Listing do
  include OrganismFixture

  # Dans le fichier asso.yml, les immos incorporelles ont
  # 4 comptes à 3 chiffres : 201, 206 et 208
  #
  def list_immo
    '20 201 206 207 208 -280'
  end

  before(:each) do
    create_minimal_organism
    @od.writings.create!({date:Date.today, narration:'ligne pour controller rubrik',
        :compta_lines_attributes=>{'0'=>{account_id:Account.find_by_number('201').id, debit:100 },
          '1'=>{account_id:Account.find_by_number('206').id, debit:10},
          '2'=>{account_id:Account.find_by_number('280').id, credit:5},
          '3'=>{account_id:Account.find_by_number('47').id, credit:105},
        }
      })
  end

  it 'la rubrique a un titre' do
    @r = Compta::Rubrik.new(@p, 'Immobilisations incorporelles', :actif,  list_immo)
    @r.title.should == 'Immobilisations incorporelles' 
  end

  it 'la rubrique donne une liste de comptes avec leur solde' do
    @r = Compta::Rubrik.new(@p, 'Immobilisations incorporelles',  :actif, list_immo)
    @r.should have(4).lines
  end

  it 'doit gentiment ignorer un compte qui n\'existe pas' do
  # même test car list_immo contient déjà le compte 20 et 207
    @r = Compta::Rubrik.new(@p, 'Immobilisations incorporelles', :actif, list_immo)
    @r.should have(4).lines
  end

  

  it 'complete_list'  do
    @r = Compta::Rubrik.new(@p, 'Immobilisations incorporelles', :actif,  '20 201 206 207 208 -280')
    @r.complete_list.should == ['Immobilisations incorporelles'] +
        @r.lines + @r.totals
  end

  it 'intègre automatiquement les sous comptes' do
    @r = Compta::Rubrik.new(@p, 'Immobilisations incorporelles', :actif, '20')
    @r.should have(3).lines
    @r.totals.should == ['Total Immobilisations incorporelles', 110.0, 0, 110.0, 0]
  end

  it 'renvoie la ligne de total' do
    @r = Compta::Rubrik.new(@p, 'Immobilisations incorporelles', :actif, '20 -280')
    @r.totals.should == ['Total Immobilisations incorporelles', 110.0, 5.0, 105.0, 0]
  end
  
 
  describe 'valeurs' do
  
    before(:each) do
      @r = Compta::Rubrik.new(@p, 'Immobilisations incorporelles',  :actif, '20 201 206 207 208 -280')
    end

    it 'brut' do
      @r.brut.should == 110.0
    end

    it 'amortissement' do
      @r.amortissement.should == 5.0
    end

    it 'alias depreciation' do
      @r.depreciation.should == 5.0
    end

    it 'net' do
      @r.net.should == 105.0
    end

    it 'previous_net égale zero si pas d exercice précédent'  do
      @p.stub(:previous_period?).and_return false
      @r.previous_net.should == 0.0
    end

    it 'previous net revoie la valeur demandée pour l exercice précedent' do
      @p.should_receive(:two_period_account_numbers).and_return(%w(201 206 207 208 -280))
      Compta::RubrikLine.any_instance.stub(:previous_net).and_return(7)
      @r.previous_net.should == 28 # 4 fois 7 car il y a 4 comptes (201 206 208 et le -280)
    end

  end

end