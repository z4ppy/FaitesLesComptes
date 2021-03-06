# coding: utf-8

require 'spec_helper'  
load 'pdf_document/simple.rb'
require 'pdf_document/page'

RSpec.configure do |c|
 # c.filter = {wip:true}
end

describe PdfDocument::Simple do  

  let(:o) {mock_model(Organism, :title=>'Ma petite affaire')}
  let(:p) {mock_model(Period, :organism=>o, :long_exercice=>'Exercice 2013')}
  let(:source) {(1..50).map {|i| mock_model(Account, number:i.to_s)}}

  def valid_options
    {
      title:'PDF Document' ,
      :select_method=>'map {|c| c}' # on utilise map car c'est un Array.
    }
  end

  describe 'création de l instance' do

    before(:each) do
      
      @simple = PdfDocument::Simple.new(p, source, valid_options)
    end

    it "est une instance de Simple" do
      @simple.should be_an_instance_of (PdfDocument::Simple)
    end

    it 'sait calculer le nombre de pages' do
      @simple.nb_pages.should == 3
    end

    it 'sait fabriquer une page' do
      PdfDocument::Page.should_receive(:new).with(1, @simple).exactly(1).times.and_return 'bonjour'
      PdfDocument::Page.should_receive(:new).with(2, @simple).exactly(1).times.and_return 'bonjour bonjour'
      PdfDocument::Page.should_receive(:new).with(3, @simple).exactly(1).times.and_return 'bonjour bonjour bonjour'
      @simple.page(1)
    end

    it 'retourne une instance de page' do
      @simple.page(1).should be_an_instance_of(PdfDocument::Page)
    end

    it 'lance une erreur si la page n existe pas' do
      expect {@simple.page(5)}.to raise_error PdfDocument::PdfDocumentError, 'La page demandée est hors limite'
    end

    it 'fetch_lines récupère les informations' do
      @simple.columns_methods=(['number'])
      @simple.should_receive(:collection).and_return  @a=double(Arel)
      @a.should_receive(:select).with(['number']).and_return @a
      @a.should_receive(:offset).and_return @a
      @a.should_receive(:limit).and_return source.slice(22, 44)
      @simple.fetch_lines(2).should be_an_instance_of Array
    end

    it 'sait préparer une ligne' do
      line = double(:number=>'101')
      @simple.columns_methods=(['number'])
      @simple.prepare_line(line).should == ['101']
    end

    it 'par défaut transforme une valeur numérique' do
      line = double(:number=>101)
      @simple.columns_methods=(['number'])
      @simple.prepare_line(line).should == ['101,00']
    end

    it 'par défaut, l alignement des colonnes est à gauche' do
      @simple.columns_methods=(['number'])
      @simple.columns_alignements.should == [:left]
    end

    it 'sait calculer par défaut des largeurs de colonnes', wip:true do
      @simple.columns_methods=(['number', 'autre'])
      @simple.columns_widths.should == [50, 50 ]
    end

     it 'sait calculer par défaut des largeurs de colonnes', wip:true do
      @simple.columns_methods=(['number'])
      @simple.columns_widths.should == [100]  
    end

    it 'sait rendre un fichier pdf', wip:true do
      
      @simple.stub_chain(:collection, :select, :offset, :limit).and_return source.slice(0,21)
      @simple.columns_methods=(['number'])
      @simple.render.should be_an_instance_of String
    end

    it 'sait rendre un partial pdf', wip:true do
     
      source.stub(:count).and_return source.size
      @simple.stub_chain(:collection, :select, :offset, :limit).and_return source.slice(0,21)
      @simple.columns_methods=(['number'])
      @pdf = PdfDocument::SimplePrawn.new(:page_size => 'A4', :page_layout => @orientation) 
      @simple.render_pdf_text(@pdf) # juste pour vérifier qu'il n'y a pas d'erreur
      # dans l'exécution de cette méthode
    end



    describe 'validations' do
      it 'should have a title' do
        @simple.title =  nil
        @simple.should_not be_valid
      end

     it 'should have a select_method' do
        vl =   {title:'PDF Document', subtitle:'Le sous titre'}
        expect {PdfDocument::Simple.new(p, p, vl)}.to raise_error PdfDocument::PdfDocumentError
      end
    end


  end

  
  
end

