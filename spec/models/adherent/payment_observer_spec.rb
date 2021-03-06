# To change this template, choose Tools | Templates
# and open the template in the editor.

# coding: utf-8

require 'spec_helper'

RSpec.configure do |c|
  # c.filter = {:wip=>true}
end

describe Adherent::Payment do
  include OrganismFixtureBis

  def create_member
    @o.members.create!(number:'001', name:'Dupont', forname:'Jean')
  end

  before(:each) do
    use_test_organism
    @m = @o.members.any? ? @o.members.first : create_member
  end

  it 'on vérifie le bridge' do
    b = @o.bridge
    b.income_book.should be_an_instance_of IncomeBook
    b.destination.should be_an_instance_of Destination

  end

  it 'et ses payment_values' do
    pv = @o.bridge.payment_values(@p)
    bac = Account.find(pv[:bank_account_account_id])
    bac.should be_an_instance_of Account
    bac.number.should == '51201'

  end

  it 'on peut enregistrer un payement' do
    p = @m.payments.new(date:Date.today, amount:125.25, mode:'CB')
    expect {p.save}.to change {Adherent::Payment.count}.by(1)
  end

  describe 'la création de payement' do

    before(:each) do
      @pay = @m.payments.new(date:Date.today, amount:125.25, mode:'CB')
    end

    after(:each) do
      Writing.delete_all
      ComptaLine.delete_all
    end

    describe 'gestion d une erreur lors de  l enregistrement' do

      it 'avec une date sans exercice' do
        @pay.date = Date.today.years_ago(2)
        @pay.save.should be_false
        @pay.errors.messages[:date].should == ['hors limite']
      end


    end

    it 'crée un in_out_writing' do
      expect {@pay.save}.to change {Adherent::Writing.count}.by(1)
    end

    it 'bridge_id enregistre l écriture d origine' do
      puts @pay.errors.messages unless @pay.valid?
      @pay.save
      w = Adherent::Writing.find_by_bridge_id(@pay.id)
      w.bridge_id.should == @pay.id
      w.bridge_type.should == 'Adherent'

    end

    it 'crée une écriture conforme aux infos entrées dans le payment'  do
      puts @pay.errors.messages unless @pay.valid?
      @pay.save
      w = Adherent::Writing.find_by_bridge_id(@pay.id)
      w.book.should == @ib
      w.narration.should == "Paiement adhérent Jean DUPONT"
      w.date.should == Date.today

      clf =  w.compta_lines.first

      clf.credit.should == @pay.amount
      clf.destination.name.should == 'Adhérents'
      clf.nature.name.should == 'Cotisations des adhérents'
      clf.debit.should == 0.0

      sl = w.support_line
      sl.account.accountable.class.should == BankAccount
      sl.nature_id.should == nil
      sl.destination_id.should == nil
      sl.debit.should == @pay.amount
      sl.credit.should == 0.0
    end

    it 'avec un chèque le accountable est bien remise de chèque' do
      @pay.mode =  'Chèque'
      puts @pay.errors.messages unless @pay.valid?
      @pay.save!

      sl = Adherent::Writing.last.support_line
      sl.account.should == @p.rem_check_accounts.first
    end

    it 'et espèces avec des espèces' do
      @pay.mode =  'Espèces'
      puts @pay.errors.messages unless @pay.valid?
      @pay.save!
      sl = Adherent::Writing.last.support_line
      sl.account.accountable.class.should == Cash
    end

  end

  describe 'mise à jour de payment' , wip:true do

    before(:each) do
      @pay = @m.payments.create!(date:Date.today, amount:125.25, mode:'CB')
      @writing_pay = Adherent::Writing.find_by_bridge_id(@pay.id)
    end

    it 'on peut retrouver l écriture' do
      ecrit = Adherent::Writing.find_by_bridge_id(@pay.id)
      ecrit.should be_an_instance_of(Adherent::Writing)

    end

    it 'n est pas possible si écriture validée' do
      @writing_pay.lock
      @pay.amount = 135.45
      @pay.save
      Adherent::Payment.last.amount.should == 125.25
    end

    describe 'mise à jour des informations'  do


      after(:each) {@o.members.find_each {|m| m.destroy}}

      it 'met à jour la date' do
        @pay.date = Date.today - 1
        @pay.save
        Adherent::Writing.find_by_bridge_id(@pay.id).date.should == Date.yesterday
      end

      it 'met à jour le membre' do
        new_m = @o.members.new(number:'002',
         name:'Dupond', forname:'Charles', tenant_id:'1')
        puts new_m.errors.messages unless new_m.valid?
        new_m.save
        @pay.member = new_m
        puts @pay.errors.messages unless @pay.valid?
        @pay.save
        Adherent::Writing.find_by_bridge_id(@pay.id).narration.should == "Paiement adhérent Charles DUPOND"
        Adherent::Writing.find_by_bridge_id(@pay.id).ref.should match(/adh 002/)

      end

      it 'met à jour le montant' do
        @pay.amount = 47.12
        @pay.save
        Adherent::Writing.find_by_bridge_id(@pay.id).compta_lines.first.credit.should == 47.12
        Adherent::Writing.find_by_bridge_id(@pay.id).support_line.debit.should == 47.12
      end

      it 'met à jour le commentaire' do
        @pay.comment = 'En faite je précise ma pensée'
        @pay.save
        Adherent::Writing.find_by_bridge_id(@pay.id).narration.should == 'En faite je précise ma pensée'
      end

    end
  end

  describe 'La suppression d un payment' do

    before(:each) do
      @pay = @m.payments.create!(date:Date.today, amount:125.25, mode:'Espèces')
      @w = Adherent::Writing.find_by_bridge_id(@pay.id)
    end

    it 'cherche l écriture associée à ce payment' do
      Adherent::Writing.should_receive(:find_by_bridge_id).with(@pay.id).and_return @w
      @pay.destroy
    end

    it 'n est pas possible si l ecriture est verrouillée' do
      @w.lock
      expect {@pay.destroy}.not_to change{Adherent::Writing.count}.by(-1)
    end

    it 'l est dans le cas contraire' do
      expect {@pay.destroy}.to change{Adherent::Writing.count}.by(-1)
    end

    it 'ce qui détruit bien sur les deux compta_lines' do
      expect {@pay.destroy}.to change{ComptaLine.count}.by(-2)
    end

  end

end
