# coding: utf-8

require 'spec_helper'

describe Transfer do
  include OrganismFixture

  before(:each) do
    create_minimal_organism
    @bb=@o.bank_accounts.create!(name: 'DebiX', number: '123Y')
  end

  def valid_attributes
    {date: Date.today, debitable: @ba, creditable: @bb, amount: 1.5, organism_id: @o.id}
  end

  context 'virtual attribute pick date' do
  
    before(:each) do
      @transfer=Transfer.new(valid_attributes)
    end
    
    it "should store date for a valid pick_date" do
      @transfer.pick_date = '06/06/1955'
      @transfer.date.should == Date.civil(1955,6,6)
   end

    it 'should return formatted date' do
      @transfer.date =  Date.civil(1955,6,6)
      @transfer.pick_date.should == '06/06/1955'
    end
 
  end

  describe 'virtual attribute fill_debitable' do

     before(:each) do
      @transfer=Transfer.new(:debitable_type=>'Model', :debitable_id=>'9')
    end
    

    it 'fill_debitable = ' do
      @transfer.fill_debitable=('Model_6')
      @transfer.debitable_id.should == 6
      @transfer.debitable_type.should == 'Model'
    end

    it 'debitable concat type and id' do
      @transfer.fill_debitable.should == 'Model_9'
    end

  end

  describe 'virtual attribute creditable' do

     before(:each) do
      @transfer=Transfer.new(:creditable_type=>'Model', :creditable_id=>'9')
    end


    it 'fill_creditable = ' do
      @transfer.fill_creditable= 'Model_6'
      @transfer.creditable_id.should == 6
      @transfer.creditable_type.should == 'Model'
    end

    it 'fill_creditable concat type and id' do
      @transfer.fill_creditable.should == 'Model_9'
    end

  end

  describe 'validations' do

    before(:each) do
      @transfer=Transfer.new(valid_attributes)
    end

    it 'should be valid with valid attributes' do
      @transfer.should be_valid
    end

    it 'but not without a date' do
      @transfer.date = nil
      @transfer.should_not be_valid
    end

    it 'nor without amount' do
      @transfer.amount = nil
      @transfer.should_not be_valid
    end

    it 'nor without debitable' do

      @transfer.debitable = nil
      @transfer.should_not be_valid

    end

    it 'nor without creditable' do
      @transfer.debitable = nil
      @transfer.should_not be_valid
    end

    it 'amount should be a number' do
      @transfer.amount = 'bonjour'
      @transfer.should_not be_valid
    end

    it 'debitable and creditable should be different' do
      @transfer.debitable = @transfer.creditable
      @transfer.should_not be_valid
    end

  end


  describe 'errors' do

    before(:each) do
      @transfer=Transfer.new(valid_attributes)
    end

    it 'champ obligatoire when a required field is missing' do
      @transfer.amount = nil
      @transfer.valid?
      @transfer.errors[:amount].should == ['champ obligatoire', 'nombre']
    end

    it 'montant ne peut être nul' do
      @transfer.amount = 0
      @transfer.valid?
      @transfer.errors[:amount].should == ['nul !']
    end

    it 'champ obligatoire pour debitable' do
      @transfer.debitable=nil
      @transfer.valid?
      @transfer.errors[:fill_debitable].should == ['champ obligatoire']
    end

     it 'champ obligatoire pour creditable' do
      @transfer.creditable=nil
      @transfer.valid?
      @transfer.errors[:fill_creditable].should == ['champ obligatoire']
    end


  end

  describe 'class method lines' do
    before(:each) do
      @t= Transfer.new(:date=>Date.today, :narration=>'test', :amount=>123.50, :creditable_id=>1, :creditable_type=>'Cash' )
    end

    it 'should build somes lines when a cash and a month is given' do
      pending
      ca =stub_model(Cash)
      ca.stub(:lines).and_return('ligne1', 'ligne2')
      Transfer.lines(ca, 4,2012).should == ['ligne1', 'ligne2']
    end

    it 'transfer create a credit line' do
      l = @t.build_credit_line
      l.should be_an_instance_of Line
      l[:line_date].should == Date.today
      l[:narration].should == 'test'
      l[:credit].should == 123.50
      l[:debit].should == 0.0
      l[:cash_id].should == 1
      l[:bank_account_id].should == nil
    end

    it 'create a debit line for a bank_account' do
      @t= Transfer.new(:date=>Date.today, :narration=>'test', :amount=>123.50, :creditable_id=>1, :creditable_type=>'BankAccount' )
      l = @t.build_credit_line
      l[:cash_id].should == nil
      l[:bank_account_id].should == 1
    end

    it 'create credit line as well' do
      @t= Transfer.new(:date=>Date.today, :narration=>'test', :amount=>123.50,
        :creditable_id=>1, :creditable_type=>'BankAccount',
        :debitable_id=>1, :debitable_type =>'BankAccount')
      l = @t.build_debit_line
      l[:credit].should == 0
      l[:debit].should == @t.amount  
      l[:cash_id].should == nil
      l[:bank_account_id].should == 1
    end


  end

end
