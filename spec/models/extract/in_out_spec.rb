# coding: utf-8

require 'spec_helper'
require "#{Rails.root}/app/models/income_outcome_book"
require "#{Rails.root}/app/models/outcome_book"

RSpec.configure do |config|  
#  config.filter = {wip:true}

end
 
describe Extract::InOut do
  
  before(:each) do
    @ob = mock_model(OutcomeBook)
    @p = mock_model(Period, start_date:Date.today.beginning_of_year, end_date:Date.today.end_of_year)
    @extract = Extract::InOut.new(@ob, @p)
  end

  it 'respond to book' do
    @extract.book.should == @ob
  end

  it 'remplit ses arguments par défaut' do
    @ext = Extract::InOut.new(@ob, @p, Date.today, Date.today >> 1)
    @ext.begin_date.should == Date.today
    @ext.end_date.should == (Date.today >> 1) 
  end

  it 'lines interroge book et filtre ' do
    @ob.should_receive(:extract_lines).with(@extract.begin_date, @extract.end_date).and_return('voila')
    @extract.lines.should == 'voila'
  end

  context "when a InOutExtract exists" do

    def line(date, debit, credit)
      double(ComptaLine, ref:'', narration:'Une compta line',
        destination:stub(:name=>'La destination'),
        nature:stub(:name=>'La nature'),
        debit:debit,
        credit:credit,
        date:date,
        writing:stub(payment_mode:'Chèque'),
        support:'Ma banque',
        locked?:true)
    end

    def double_lines
         ls = []
      3.times do |i|
        1.upto(10) do |j|
          ls << line(@extract.begin_date >> i, j, 0)
        end
      end
      ls

    end

    before(:each) do
      @extract.stub(:lines).and_return(@ls = double_lines)
      @ob.stub(:cumulated_at).with(@extract.begin_date - 1, :debit).and_return 5
      @ob.stub(:cumulated_at).with(@extract.begin_date - 1, :credit).and_return 18
    end

    it 'il y a 30 lignes' do
      @extract.lines.count.should == 30 
    end

    it 'délègue le calcul des soldes cumumés à Book' do
      @ob.should_receive(:cumulated_at).with(Date.today, 'debit')
      @extract.cumulated_at(Date.today, 'debit')
    end

    it "knows the total debit" do
      pending 'A tester dans la classe Extract::Base puis supprimer d ici'
       @extract.total_debit.should == 165
    end

    it "knows the total credit" do
      pending 'A tester dans la classe Extract::Base puis supprimer d ici'
      @extract.total_credit.should == 0
    end

    it "respond to debit_before" do
      @extract.debit_before.should == 5
    end

    it "respond to debit_before" do
      @extract.credit_before.should == 18
    end

    it 'peut produire un csv' do
      @extract.to_csv
    end

    it 'peut produire un pdf' do
      Editions::Book.should_receive(:new).with(@p, @extract)
      @extract.to_pdf
    end

    it 'est définitif avec des lignes toutes verrouillées' do
      @extract.should_not be_provisoire
    end

    it 'est provisoire si des lignes ne sont pas verrouillées' do
      @ls[1].stub(:locked?).and_return false
      @extract.should be_provisoire
    end

   
  end
end
