# coding: utf-8

require 'prawn'

module PdfDocument
  
  # classe ayant pour but de produire concrètement le document PDf demandé
  # Des méthodes communes comme stamp et entetes facilitent le remplissage des pages
  # PdfDocument::PrawnBase hérite de Prawn::Document et est la base des autres PdfDocument::Prawn
  # ou des Editions::PrawnSheet pour construire le fichier des bilans ou éléments de la liasse
  # et Editions::PrawnBalance pour construire un fichier balance.
  # 
  # Editions::PrawnBase apporte les méthodes communes comme #entetes pour 
  # remplir la partie haute de la page ou #jc_fill_stamp qui produit le tampon.
  # 
  #
  class BasePrawn < Prawn::Document
    
    # définit le style d'une ligne en fonction de la profondeur de la rubrique
    # pour rappel, depth = -1 pour une ligne de détail de compte
    # sinon depth = 0 pour la rubrique racine puis +1 à chaque fois qu'on 
    # descend dans l'arbre des rubriques.
    def style(depth)
      return :bold if (depth == 0 || depth == 1 || depth == 2)
      return :italic if depth == -1
    end
    
  
    # méthode pour remplir le document avec le contenu des différentes pages
    # il suffit de surcharger cette méthode dans les classes filles pour personnaliser
    # le document produit.
    # On peut aussi créer d'autres fill_... si on veut avoir plusieurs types de documents
    # pour un même objet (par exemple fill_actif_pdf et fill_passif_pdf pour les Sheet).
    def fill_pdf(document, numeros= true) # la table des pages
      jclfill_stamp(document.stamp) # on initialise le tampon
      #
      # on démarre la table proprement dite
      # en calculant la largeur des colonnes
      col_widths = document.columns_widths.collect { |w| width*w/100 }
      
      document.pages.each_with_index do |current_page, index|
        
        pad(05) { font_size(12) {entetes(current_page, cursor) } }
        
        stroke_horizontal_rule

        table [current_page.table_title],
          :cell_style=>{:padding=> [1,5,1,5], :font_style=>:bold, :align=>:center }    do
          col_widths.each_with_index {|w,i| column(i).width = w}
        end


        # la table des lignes proprement dites
        table current_page.table_lines ,  :row_colors => ["FFFFFF", "DDDDDD"],  :header=> false , :cell_style=>{:padding=> [1,5,1,5], :height => 16, :overflow=>:truncate} do
          col_widths.each_with_index {|w,i| column(i).width = w}
          document.columns_alignements.each_with_index {|alignement,i|  column(i).style {|c| c.align = alignement}  }
        end

        stamp 'fond'

        start_new_page unless document.nb_pages == index+1

      end
      
      numerote if numeros
    end
    
    # réalise la pagination des fichiers pdf.
    # Est en zone public car peut être appelé par un Editions::Sheet car 
    # un tel modèle regroupe plusieurs documents et on doit faire la numérotation
    # en fin de construction du pdf pour pouvoir afficher page x/y
    def numerote
      number_pages("page <page>/<total>",
        { :at => [bounds.right - 150, 0],:width => 150,
          :align => :right, :start_count_at => 1 })
    end
    
    protected 
    
    
    # la largeur de la page
    def width
      bounds.right
    end
    
    
    
    
    # les entêtes de pages. 3 bounding_box donnant respectivement la partie gauche
    # de l'entete, celle du milieu et celle de droite
    def entetes(page, y_position)
      
      
      bounding_box [0, y_position], :width => 150, :height => 40 do
        text page.top_left

      end

      bounding_box [150, y_position], :width => width-300, :height => 40 do
        font_size(20) { text page.title.capitalize, :align=>:center }
        text page.subtitle, :align=>:center if page.subtitle
      end

      bounding_box [width-150, y_position], :width => 150, :height => 40 do
        text page.top_right, :align=>:right
      end

    end
    
   

    
    
    # Définit une méthode tampon pour le PrawnSheet qui peut ensuite être appelée 
    # par fill_actif_pdf et fill_passif_pdf 
    #
    def jclfill_stamp(text)
      if stamp_dictionary_registry['fond'].nil?
        create_stamp("fond") do
          rotate(stamp_rotation) do
            fill_color "bbbbbbb"
            font_size(120) do
              text_rendering_mode(:stroke) do
                draw_text(text, :at=>stamp_position)
              end
            end
            fill_color "000000"
          end
        end
      end
    end
    
    def stamp_rotation
      page.layout == :landscape ? 30 : 65
    end
    
    def stamp_position
      page.layout == :landscape ? [200, -20] : [250, -150]
    end
  
  end
 
  
  
  
end