# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# spec request for testing admin books

describe 'vue books index' do
  include OrganismFixture 

  before(:all) do
    clean_test_database 
  end
  
  before(:each) do
    Book.count.should == 0
    create_minimal_organism

  end

  it 'check minimal organism' do
    Organism.count.should == 1
    Book.count.should == 2
  end

  describe 'new book' do
    
    it "affiche la page new" do
      visit new_admin_organism_book_path(@o)
      response.should contain("Création d'un livre")
      response.should contain('Type')
    
    end

    it 'remplir correctement le formulaire crée une nouvelle ligne' do
      visit new_admin_organism_book_path(@o)
      fill_in 'book[title]', :with=>'Recettes test'
      fill_in 'book[description]', :with=>'Un deuxième livre de recettes'
      choose 'Recettes'
      click_button 'Créer le livre'
      @o.books.count.should == 3
      @o.books.last.book_type.should == 'Recettes'
    end

    it 'dans la vue index,un livre peut être détruit' do
      @o.income_books.create!(:title=>'livre de test')
      @o.should have(3).books
      # à ce stade chacun des livres est vierge et peut donc être détruit.
      visit admin_organism_books_path(@o)
      within 'table tr:nth-child(3)' do |scope|
        scope.should contain('livre de test')
        pending 'impossible de cliquer sur la box de confirmation sans selenium'
        scope.click_link 'Supprimer'
      end
      @o.should have(2).books
    end

    it 'un livre avec des écritures ne présente pas de lien destruction'

    it 'on peut le choisir dans la vue index pour le modifier' do
      visit admin_organism_books_path(@o)
      click_link "Modifier"
      response.should contain("Modification d'un livre")
    end

    it 'dans la vue edit, le type n est pas disponible' do
      visit edit_admin_organism_book_path(@o, @o.books.last)
      response.should_not contain('Type')
    end

    it 'mais on peut changer les deux autres champs' do
      visit edit_admin_organism_book_path(@o, @o.books.last)
      fill_in 'book[title]', :with=>'modif du titre'
      click_button 'Modifier ce livre'
      response.should contain('modif du titre') # on est revenu dans le template index
      # et la modif est prise en compte.
    end

  
 

  end
end

