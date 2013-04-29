# coding: utf-8

require 'spec_helper'

RSpec.configure do |c|
  # c.filter = {:wip=> true }
end 


describe BankExtractLine do  
  include OrganismFixture 

  before(:each) do 
    create_minimal_organism  

    @be = @ba.bank_extracts.create!(:begin_date=>Date.today.beginning_of_month, 
      end_date:Date.today.end_of_month,
      begin_sold:1,
      total_debit:2,
      total_credit:5)
    @d7 = create_outcome_writing(7)  
    @d29 = create_outcome_writing(29)
    @ch97 = create_in_out_writing(97, 'Chèque')
    @ch5 = create_in_out_writing(5, 'Chèque')
    @cr = create_in_out_writing(27) # une recette
    @cd = @ba.check_deposits.new(deposit_date:(Date.today + 1.day)) 
    @cd.checks << @ch97.support_line << @ch5.support_line
    @cd.save!

  end

  it 'les écritures doivent être valides' do
    @d7.should be_valid
    @d29.should be_valid
    @ch97.should be_valid
    @ch5.should be_valid
  end

  describe 'validations' do
    it 'un bank_ectract_line ne peut être vide' do
      bel = @be.bank_extract_lines.new
      bel.should_not be_valid
      bel.errors.messages[:base].should == ['empty']
    end


  end


  describe 'un extrait bancaire avec les différents éléments' do

    before(:each) do
      @be.bank_extract_lines << @be.bank_extract_lines.new(:compta_lines=>[@d7.support_line])
      @be.bank_extract_lines << @be.bank_extract_lines.new(:compta_lines=>[@d29.support_line])
      @be.bank_extract_lines << @be.bank_extract_lines.new(:compta_lines=>[@cd.debit_line])
      @be.save!
    end


    it 'checks values' do
      @be.total_lines_credit.to_f.should == 36
      @be.total_lines_debit.to_f.should == 102
    end

    it 'checks positions' do
      @be.bank_extract_lines.all.map {|bel| bel.debit}.should == [0,0,102]
      @be.bank_extract_lines.all.map {|bel| bel.credit}.should == [7,29,0]
      @be.bank_extract_lines.all.map {|bel| bel.position}.should == [1,2,3]
    end

    describe 'lock_line'  do
      before(:each) do
        @be.bank_extract_lines << @be.bank_extract_lines.new(:compta_lines=>[@cr.support_line])
        @be.bank_extract_lines.each {|bel| bel.lock_line }
      end

      it 'verif ' do
        @g = @be.bank_extract_lines.first
        @g.compta_lines(true).each {|l| l.should be_locked} 
      end


      it 'lock_line doit verrouiller les lignes et les siblings' do
        

        ComptaLine.where('payment_mode = ?', 'Virement').all.each do |l|
          puts l.inspect unless l.locked
           l.should be_locked
         end
      end

      it 'pour une remise de chèque, il faut aussi verrouiller les lignes d origine' do
       ComptaLine.where('payment_mode = ?', 'Chèque').all.each do |l|
          l.should be_locked
        end
      end
    end
    

   
    describe 'testing move_higher and move_lower' do

      before(:each) do
        @bel7, @bel29, @bel102 = *@be.bank_extract_lines.all
      end

      it 'tst du splat' do
        @be.bank_extract_lines.order('position').all.should  == [@bel7, @bel29, @bel102]
      end

      it '@bel7 is in first position' do
        @bel7.position.should == 1
      end

      it 'move lower' do
        @bel7.move_lower
        @be.bank_extract_lines.order('position').all.should  == [@bel29, @bel7, @bel102]
      end


    end

    describe 'regroup'  do

      before(:each) do
        @bel7, @bel29,  @bel102 = *@be.bank_extract_lines.order('position')
      end

      it 'regroup diminue le nombre de lignes' do
        @bel7.regroup @bel29
        @be.should have(2).bank_extract_lines
        @be.bank_extract_lines.first.should have(2).compta_lines
        @be.bank_extract_lines.last.should have(1).compta_lines
      end

      it 'regroup met à jour le follower' do
        @bel7.lower_item.should == @bel29
        @bel29.lower_item.should == @bel102
        @bel7.regroup @bel29
        @bel7.lower_item.should == @bel102
      end

      it 'regroup en partant de la fin' do
        @bel29.regroup @bel102
        @bel29.should have(2).compta_lines
        @bel7.regroup @bel29
        @bel7.lower_item.should be_nil
        @bel7.should have(3).compta_lines
      end

    end

    describe 'degroup'  do
      before(:each) do
        @bel7, @bel29,  @bel102 = *@be.bank_extract_lines.order('position')
      end

      it 'renvoie lui même si moins de 2 lignes' do
        @bel7.degroup.should == @bel7
      end



      it 'un groupe de deux lignes renvoie deux lignes' do
        group = @bel29.regroup @bel102
        group.degroup.should be_an_instance_of Array
      end

      it 'un groupe de 3 lignes renvoie 3 lignes'  do
        group = @bel29.regroup(@bel102).regroup(@bel7)
        degroup = group.degroup
 # TODO check_deposit devrait pouvoir répondre à support_line car celà complique
 # inutilement d'avoir des méthodes différentes.
        degroup.first.should == @bel29
        degroup.first.compta_lines.should == [@d7.support_line]
        degroup.second.compta_lines.should ==[@d29.support_line]
        degroup.third.compta_lines.should == [@cd.debit_line]
      end
    end

    describe 'chainable'  do

      before(:each) do
        @bel7, @bel29,  @bel102 = *@be.bank_extract_lines.order('position')
      end

      it 'a check_deposit_bank_extract_line is not chainable' do
        @bel102.should_not be_chainable
      end

      it ' a bel followed by a standard bel is chainable' do
        @bel7.should be_chainable
      end

      it ' a bel followed by a check_deposit is not chainable' do
        @bel29.position.should == 2
        @bel29.should_not be_chainable
      end

      it 'a bel is chainable only if both debit or both credit'  do
        bel_cr = @be.bank_extract_lines.create!(compta_lines:[@cr.support_line])
        bel_cr.move_to_top
        bel_cr.should_not be_chainable

      end

      it 'move_lower' do
        @be.bank_extract_lines.order('position').all.should  == [@bel7, @bel29, @bel102]
        @bel102.move_higher
        @be.bank_extract_lines.order('position').all.should  == [@bel7, @bel102, @bel29]
      end

      context 'avec l ordre bel7, 102 et 29' do

        before(:each) do
          @bel102.move_higher
          @cel7, @cel102,  @cel29 = *@be.bank_extract_lines.order('position')
          
        end

        it 'cel29 est le dernier' do
          @cel7.position.should == 1
          @cel102.position.should == 2
          # @bel102.move_higher
          @cel29.position.should == 3
          #be_last
        end

        it 'aucun n est chainable' do
          @cel7.should_not be_chainable
          @cel102.should_not be_chainable
          @cel29.should_not be_chainable
        end


      end


    end

  end



end
