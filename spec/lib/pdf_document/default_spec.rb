# coding: utf-8

require 'spec_helper'
# require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require 'pdf_document/simple.rb'
require 'pdf_document/default.rb'
require 'pdf_document/page'

RSpec.configure do |c|
  # c.filter = {wip:true}  
end

describe PdfDocument::Default do 

  let(:o) {mock_model(Organism, title:'Organisme test')} 
  let(:p) {mock_model(Period, organism:o,
      start_date:Date.today.beginning_of_year,
      close_date:Date.today.end_of_year,
      long_exercice:'Exercice 2012',
      compta_lines:[ComptaLine.new, ComptaLine.new])}

  def valid_options
    {
      title:'PDF Document' ,
      subtitle:'Le sous titre',
      :select_method=>'compta_lines'
    }
  end

  context 'minimal_options et pas encore de source' do 

    before(:each) do
      @default = PdfDocument::Default.new(p, p, valid_options)
    end

    it "should exists", wip:true do
      @default.should be_an_instance_of (PdfDocument::Default)
    end

    it 'respond_to title' do
      @default.title.should == 'PDF Document'
    end

    it 'respond to sub_title' do
      @default.subtitle.should == 'Le sous titre'
    end

    it 'respond to organism_name' do
      @default.organism_name.should == 'Organisme test'
    end

    it 'respond to exercice' do
      @default.exercice.should == 'Exercice 2012'
    end

    # le _ ci dessous symbolise un espace
    it 'give the time of creation au format 25 juillet 2012 07:54:14 ou _3 août..' do
      I18n::l(@default.created_at).should match(/^(\s\d|\d{2})\s(\w|é|û)*\s\d{4}\s\d{2}:\d{2}:\d{2}$/)
    end

    it 'default from_date and to_date are from period' do
      @default.from_date.should == p.start_date
      @default.to_date.should == p.close_date
    end

    it 'has a default value nb_lines_per_page' do
      @default.nb_lines_per_page.should == 22
    end

  end

  context 'options complémentaires' do
    
    
    it 'accepts options from_date' do
      h = valid_options.merge({:from_date=>Date.today.beginning_of_month})
      @default = PdfDocument::Default.new(p, p, h)
      @default.from_date.should == Date.today.beginning_of_month
    end

    it 'accepts options to_date' do
      h = valid_options.merge({:to_date=>Date.today.end_of_month})
      @default = PdfDocument::Default.new(p, p, h)
      @default.to_date.should == Date.today.end_of_month
    end

    it 'accepts options nb_lines_per_page' do
      h = valid_options.merge({:nb_lines_per_page=>30})
      @default = PdfDocument::Default.new(p, p, h)
      @default.nb_lines_per_page.should == 30
    end

    describe 'stamp' do
      it 'has a nil default stamp' do
        @default = PdfDocument::Default.new(p, p, {})
        @default.stamp.should == nil
      end

      it 'une option peut permettre de préciser le stamp' do
        pdf = PdfDocument::Default.new(p, p, valid_options.merge(stamp:'Provisoire'))
        pdf.stamp.should == 'Provisoire' 
      end
    end

    it 'peut modifir l alignement des colonnes' do
      pdf = PdfDocument::Default.new(p, p, {})
      pdf.columns_alignements = [:left, :left]
      pdf.columns_alignements.should == [:left, :left]
    end
  end

  context 'un listing sans ligne' do 
    
    subject {PdfDocument::Default.new(p, p, valid_options)}

    before(:each) do
      subject.columns_to_totalize = [4,5]
      subject.stub(:fetch_lines).and_return([])
    end

    it 'a quand même une page' do
      p.stub_chain(:send, :range_date, :count).and_return 0
      subject.nb_pages.should == 1
    end

    it 'avec un total de 0', wip:true do
      
      subject.stub(:nb_pages).and_return 1
      subject.page(1).table_total_line.should == ['Totaux', '0,00', '0,00']
      subject.page(1).table_to_report_line.should == ['Total général', '0,00', '0,00']
    end
  end

 
  context 'création des pages' do 

    let(:arel) {double(Arel,  first:mock_model(ComptaLine))}
    let(:source) {mock_model(Account, title:'Achats', number:'60',
        compta_lines:arel )}

    before(:each) do
      arel.stub_chain(:range_date, :count).and_return 100
      @default = PdfDocument::Default.new(p, source, valid_options)
    end

    it 'connaît son nombre de pages' do
      @default.nb_pages.should == 5
    end

    it 'est capable de fournir une page pour le nb_pages' do
      1.upto(@default.nb_pages) do |i|
        @default.page(i).should be_an_instance_of PdfDocument::Page
      end
    end

    it 'appelé une page hors limite déclenche une erreur' do
      expect {@default.page(6)}.to raise_error PdfDocument::PdfDocumentError, 'La page demandée est hors limite'
      expect {@default.page(0)}.to raise_error PdfDocument::PdfDocumentError, 'La page demandée est hors limite'
    end

    it 'un doc doit pouvoir énumérer ses pages' do
      list = []
      @default.each_page {|p| list << p.number }
      list.should == [1,2,3,4,5] 
    end

    it 'default select_method' do
      @default.select_method.should == 'compta_lines'
    end

    it 'raise error si source ne repond pas à select method' do
      
    end

    it 'on peut modifier la select_method = ' do 
      # title ne répondrait pas aux attentes mais est suffisant pour le test
      @default.select_method = :title
      @default.select_method.should == :title
    end 


    it 'on peut sélectionner les colonnes' do
      @default.columns_select=   %w(line_date ref nature_id destination_id debit credit)
      @default.columns_select.should == %w(line_date ref nature_id destination_id debit credit)
    end

    it 'choisir des colonnes crée un tableau des alignements' do
      @default.columns_methods =    %w(line_date ref nature_id destination_id debit credit)
      @default.columns_alignements.should == [:left, :left,:left,:left,:right, :right]
    end

   
    describe 'les méthodes sur les colonnes' do
      it 'par défaut les colonnes utilisent le nom de la colonne, préfixées' do 
        list = ComptaLine.column_names.collect {|cn| "compta_lines.#{cn}"}
        @default.columns_methods.should == list
      end

      it 'mais on peut définir d autres méthodes' do
        @default.columns_methods = %w(bonjour ref nature_id destination_id debit credit)
        @default.columns_methods.should == ['bonjour','ref', 'nature_id','destination_id', 'debit', 'credit']
      end

   

    end

    describe 'les largeurs de colonnes' do

      before(:each) do
        @default.columns_methods =   %w(line_date ref nature_id destination_id debit credit)
      end

      it 'on a une largeur de colonnes par défaut' do
        @default.columns_widths.should == 6.times.collect {|t| 100.0/6 }
      end

      it 'on peut imposer les 6 colonnes' do
        @default.columns_widths= [10,20,30,10,15,15]
        @default.columns_widths.should == [10,20,30,10,15,15]
      end

      it 'gestion des erreurs des size' do
        expect {@default.columns_widths= [10,20,30,50]}.to raise_error PdfDocument::PdfDocumentError
      end

    end

    

    describe 'gestion des totaux' do

      before(:each) do
        @default.columns_methods=  %w(line_date ref nature_id destination_id debit credit)
        @default.columns_widths= [10,20,30,10,15,15]
      end

      it 'set avec un array vide génère une erreur' do
        expect { @default.columns_to_totalize = []}.to raise_error 'Le tableau des colonnes ne peut être vide'
      end

      it 'définir les colonnes permet de définir les largeurs' do
        bcw4 = @default.columns_widths[4]
        bcw5 = @default.columns_widths[5]
        @default.columns_to_totalize = [4,5]
        @default.total_columns_widths.should == [100 - bcw4 - bcw5, bcw4, bcw5 ]
      end

      it 'définir une colonne qui n est pas la dernière complète les colonnes pour avoir 100' do
        bcw4 = @default.columns_widths[4]
        bcw5 = @default.columns_widths[5]
        @default.columns_to_totalize = [4]
        @default.total_columns_widths.should == [100 - bcw4 - bcw5, bcw4, bcw5 ]
      end

      it 'peut fixer la première ligne de report' do
        @default.first_report_line = ['Soldes', 100, 20]
        @default.first_report_line.should ==  ['Soldes', 100, 20]
      end

      it 'gestion des totaux de la page' do
        pending 'voir si fait dans la classe page'
      end

    end

    it 'peut créer un fichier pdf' do
      @default.should respond_to(:render)
    end
    
    it 'peut vraiment le faire' do
      pending 'retravailler toutes ces specs avant de tenter un render'
      @default.render
    end

    # l'action de render est testée dans la un spec de vue
  end



  
end

