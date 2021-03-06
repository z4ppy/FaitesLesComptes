# -*- encoding : utf-8 -*-

module ApplicationHelper
  # icon_to s'utilise comme link_to mais prend
  # en argument le nom d'un fichier placé dans le sous répertorie icones/
  # icon_to construit l'image_tag avec le nom sans l'extension comme propriété alt et
  # la même chose comme balise title pour le lien.
  #
  def icon_to(icon_file, options={}, html_options={})
    raise ArgumentError unless icon_file
    title = alt = icon_file.split('.')[0].capitalize

    html_options[:title] ||=title
    html_options[:class] ||= 'icon_menu'
    # html_options[:tabindex]= "-1"
    img_path="icones/#{icon_file}"
    link_to image_tag(img_path, :alt=> alt), options, html_options
  end

  def two_decimals(montant)
    sprintf('%0.02f',montant)
  rescue
    '0.00'
  end


  # utilisé pour donner la classe active ou inactive aux éléments du menu
  # supérieur (Saisie/consult, Admin, Compta).
  #
  # Le but est que l'espace actuel soit marqué comme actif tandis que les autres sont inactifs
  #
  # Il y a 3 espaces de noms : main (correspondant à saisie/consult), admin et compta
  #
  #
  def active_inactive(name)
    name == space ? 'active' : 'inactive'
  end

  # fournit un conseil basé sur l'action et le nom du controller si
  # la clé existe dans le fichier conseil.fr.yml.
  # Ce conseil est utilisé dans le _flash_partial.html.haml
  def give_advice
    key = ['conseils', controller.class.name.split('::'), controller.action_name].join('.')
    conseil = I18n.t(key, :default=>'')
    conseil.gsub!('</p>', '</p><p>')

    unless conseil.empty?
      content_tag(:div, 'class'=>"alert conseil") do
        content_tag(:a, 'x', {'class'=>'close', 'data-dismiss'=>'alert'}) +
          content_tag(:div, conseil.html_safe)
      end
    end
  end



  # Affiche le titre en haut à gauche des vues
  def header_title
    if @organism && @organism.title
      html = sanitize(@organism.title)
      html += " : #{@period.long_exercice}" unless @period.nil?
    else
      html="Faites les comptes"
    end
    html
  end

  def debit_credit(montant, precision = 2)
    return montant if montant.is_a? String
    if montant > -0.01 && montant < 0.01
      '-'
    else
      number_with_precision(montant, :precision=> precision)
    end
  rescue
    ''
  end

  def insecable_debit_credit(montant, precision=2)
    res = debit_credit(montant, precision)
    res.gsub(' ', '&nbsp;').html_safe
  end

  # export_icons permet d'afficher les différentes icones d'export.
  #
  # Dans la vue, on utilise export_icons avec comme argument opt les paramètres dont on a besoin pour
  # permettre au serveur de répondre. Typiquement tout simplement export_icons(params)
  # FIXME ceci renvoie le token également en clair
  #
  def export_icons(opt)
    html = icon_to('pdf.png', url_for(opt.merge(:format=>'pdf')), :id=>'icon_pdf')
    html += csv_export_icons(opt)
    html.html_safe
  end

  def csv_export_icons(opt)
    html = icon_to('table-export.png', url_for(opt.merge(:format=>'csv')), :id=>'icon_csv', title:'csv', target:'_blank')
    html += icon_to('report-excel.png', url_for(opt.merge(:format=>'xls')), :id=>'icon_xls', title:'xls', target:'_blank')
    html.html_safe
  end

  # l'action pour le pdf est ici 'produce_pdf'. Dans les controllers cette
  # action est confiée à un job d'arrière plan.
  def delayed_export_icons(opt)
    html = icon_to('pdf.png', url_for(opt.merge(:action=>'produce_pdf')), {:id=>'delayed_icon_pdf', :remote=>true})
    html += csv_export_icons(opt)
    html.html_safe
  end



  # ordinalize date s'appuie sur ordinalize qui est redéfini dans
  # config/initializers/inflections.rb
  def ordinalize_date(d)
    "#{d.day.ordinalize} #{I18n.l(d, :format=>:month_year)}"
  end

  def editable?(payment)
    w = Adherent::Writing.find_by_bridge_id(payment.id)
    w.editable? if w
  end


  def option_groups_from_collection_for_select_with_datas(collection, group_method, group_label_method, option_key_method, option_value_method, selected_key = nil)
    collection.map do |group|
      option_tags = options_from_collection_for_select(
        group.send(group_method), option_key_method, option_value_method, selected_key)
      if group.argument
        mes_options = {label: group.send(group_label_method)}.merge(group.html_options)

      else
        mes_options =  {label: group.send(group_label_method)}
      end
      content_tag(:optgroup, option_tags, mes_options)
      end.join.html_safe
  end

    # Pour l'affichage d'une liste de mois dans les différentes vues avec des lignes
    # telles que les livres, les caisses,...
    #
    # Les arguments sont period (l'exercice), un hash reprenant les options nécessaires,
    # en l'occurence, l'action, le controller, et les arguments complémentaires éventuels.
    #
    # Un argument optionnel booleen indique si on veut que le lien 'tous' soit présent.
    # Par exemple, pour les livres c'est souhaitable, mais pour les contrôles de caisse
    # normalement tous les jours, ce n'est pas forcément idéal.
    #
    # Exemple submenu_mois(@period, {action:'index', controller:'cash_controls', :cash_id=>@cash.id}, false)
    # pour afficher les mois et renvoyer vers les contrôles de caisse.
    #
    # On aura comme affichage les liens jan fév mar... chacun pointant vers l'action voulue
    #
    #
    def submenu_mois(period, opt, all = true)
      plm = period.list_months.collect do |m|
        content_tag :li , :class=>"#{current_page?({:mois=>m.month, :an=>m.year}) ? 'active' : 'inactive'}" do
          link_to_unless_current(m.to_short, url_for(opt.merge({:mois=>m.month, :an=>m.year})))
        end
      end
      if all
        tous = content_tag :li, :class=>"#{current_page?(:mois=>'tous') ? 'active' : 'inactive'}" do
          link_to_unless_current('tous', url_for(opt.merge({:mois=>'tous'})))
        end
        plm.append tous
      end
      plm.join.html_safe
    end




    protected

    # renvoie l'espace dans lequel on est : compta, admin ou main
    # mais ce peut être aussi adherent ou autre prefixe;
    #
    # Si il n'a pas de prefix connu, c'est qu'on est dans l'espace principal
    # et alors renvoie main
    #
    def space
      requ = request
      return 'main' unless requ
      # request_path est par exemple /admin/organisms/9
      request_uri = requ.path.slice(1..-1) # on enlève le leading /
      prefix = request_uri.split('/').first
      return prefix if prefix.in? %w(admin compta adherent)
      'main'
    end




end
