module Utilities
  # Cloner a pour objet de prendre une comptabilité (actuellement un organisme)
  # et de faire la copie de cette comptabilité en conservant les références
  #
  class Cloner < ActiveRecord::Base

    self.table_name = 'flccloner'
    attr_accessor :org_source

    # trouve l'organisme que l'on souhaite copier à l'aide de l'attribut
    # old_org_id
    def from_org
      raise 'Vous devez préciser l\'attribut old_org_id' unless old_org_id
      Organism.find(old_org_id)
    end

    # Duplique un organisme en effectuant une copie de tous les enregistrements
    # qui en dépendent en maintenant les références.
    # Le seul champ modifié est le champ commentaire de l'organisme
    def clone_organism(comment=nil)
      # TODO : rajouter une transaction

      # on trouve l'organisme demandé par le clone
      @org_source = from_org
      # ON efface les données de la table flccloner
      delete_trace
      # création du nouvel organisme
      create_new_org(comment)
      # on copie les différentes données des tables
      new_org_id  = clonage
      # La création du holder doit se faire dans le controller car c'est lui
      # qui a la connaissance du user

      new_org = Organism.find(new_org_id)
      # reconstruire les rubriks
      new_org.send(:reset_folios)
      # on renvoie le nouvel id
      return new_org_id


    end

    # Appelle successivement les différentes fonctions SQL permettant
    # la recopie des lignes voulues avec maintien des références
    #
    # Attention à l'ordre des tables, puisqu'il y a des dépendances à
    # respecter
    #
    # Toute modification du schéma doit être étudiée ici pour
    # vérifier qu'il n'y a pas d'impact ou modifier en conséquence
    #
    #
    def clonage
      # Lecture du nouvel id dans la table
      infos = Utilities::Cloner.where('name = ? AND old_org_id = ?',
        'Organism', @org_source.id).first
      # puis utilisation des ces infos pour appeler successivement toutes
      # les fonctions SQL nécessaires dans l'ordre des demandes
      #
      functions = %w(copy_sectors copy_periods copy_adherent_members
      copy_nomenclatures copy_adherent_payments copy_adherent_coords
      copy_adherent_adhesions copy_adherent_reglements
      copy_bank_accounts copy_cashes copy_bank_extracts copy_cash_controls
      copy_books copy_destinations copy_accounts copy_natures
      copy_writings copy_compta_lines copy_bank_extract_lines copy_check_deposits
      copy_imported_bels copy_masks copy_subscriptions copy_adherent_bridges
      refill_check_deposits)


      requete = ''
      functions.each do |f|
        requete << "SELECT #{f}(#{infos.old_org_id}, #{infos.new_org_id});"
        end
      requete << "SELECT clone_fill_bridge_id(#{infos.old_org_id}, #{infos.new_org_id});"

      Utilities::Cloner.connection.execute(requete)
      return infos.new_org_id

    end


      # Création d'un organisme copie de @org_source par
      # une reqûete sql avec insertion de l'enregistrement dans la table
      # flccloner
    def create_new_org(comment)
      Organism.find_by_sql("WITH ret AS
(INSERT INTO organisms(title, created_at, updated_at,
           status, version, comment, siren, postcode, tenant_id)
           VALUES ('#{quote_string @org_source.title}',
           '#{@org_source.created_at}'::timestamp,
           '#{@org_source.updated_at}'::timestamp,
           '#{quote_string @org_source.status}',
           '#{quote_string @org_source.version}',
           '#{quote_string new_comment(comment)}',
           '#{quote_string @org_source.siren}',
           '#{quote_string @org_source.postcode}',
           '#{@org_source.tenant_id}')
            RETURNING id )
INSERT INTO flccloner(name, old_id, new_id, old_org_id, new_org_id)
VALUES('Organism',
        #{@org_source.id},
        (SELECT id FROM ret LIMIT 1),
        #{@org_source.id},
        (SELECT id FROM ret LIMIT 1));")

    end

    # On retire tous les enregistrements qui font référence à l'organisme
    # source
    def delete_trace
      Utilities::Cloner.find_by_sql("DELETE FROM flccloner WHERE
         old_org_id = #{@org_source.id};")
    end

    def new_comment(comment)
      raise StandardError, '@org_source, n\'a pas été instancié' unless @org_source
      return comment if comment
      return @org_source.comment unless @org_source.comment.blank?
    end


    # méthode de création des fonctions nécessaires à la recopie
    # Sera utilisé dans une migration après mise au point
    def self.create_clone_functions
      # on commence par les classes de premier niveau
      %w(nomenclatures sectors periods).each do |t|
        create_function(sql_copy_first_level(t))
      end
      # partie Adhérents
      create_clone_adherent_functions
      # les classes de second niveau : bank_account, cash, books et destinations
      # lesquelles ont toutes comme champ secondaire sector_id
      %w(bank_accounts cashes books destinations).each do |t|
        create_function(sql_copy_n_refs('organism_id', ['sector_id'], t))
      end
      # les classes qui découlent directement des précédentes
      # avec un seul champ dépendant
      create_function(sql_copy_one_ref('bank_account_id', 'bank_extracts'))
      create_function(sql_copy_one_ref('cash_id', 'cash_controls'))

      # la partie comptabilité avec les comptes
      create_function(sql_copy_n_refs('period_id',
          ['sector_id', 'accountable_id'], 'accounts',
           :polymorphic=>'accountable_id'))
      # les natures
      create_function(sql_copy_n_refs('book_id', %w(period_id account_id), 'natures'))
      # puis les écritures
      create_function(sql_copy_n_refs('book_id', ['bridge_id'], 'writings',
         bridge_id:Adherent::Payment))
      # les remises de chèques (attention à l'ordre)
      create_function(sql_copy_n_refs('bank_account_id',
        ['writing_id'], 'check_deposits'))
      # les compta_lines
      create_function(sql_copy_n_refs('writing_id',
        %w(nature_id destination_id account_id), 'compta_lines'))
      # et enfin les folios
      create_function(sql_copy_n_refs('nomenclature_id',
        %w(sector_id), 'folios'))


      create_clone_mask_functions
      create_clone_bank_functions
      # les données du bridge adhérent
      create_function(sql_copy_n_refs('organism_id',
        %w(bank_account_id cash_id destination_id income_book_id),
        'adherent_bridges', {modele:Adherent::Bridge, income_book_id:Book}))
      # on reremplit les compta_lines.check_deposit_id car la structure de la
      # base de données ne permet pas de trouver un enchaintement pour ce
      # champ
      create_refill_check_deposit_function
      #
      create_clone_fill_bridge_id
    end


    def self.create_clone_mask_functions
      create_function(sql_copy_n_refs('organism_id',
        %w(book_id destination_id), 'masks'))
      create_function(sql_copy_one_ref('mask_id', 'subscriptions'))
    end

    def self.create_clone_bank_functions
      create_function(sql_copy_n_refs('bank_extract_id',
        %w(compta_line_id), 'bank_extract_lines'))
      create_function(sql_copy_n_refs('bank_account_id',
        %w(writing_id nature_id destination_id), 'imported_bels'))
    end

    def self.create_clone_adherent_functions
      # plus Adherent::Member
      create_function(sql_copy_first_level('adherent_members',
        modele:Adherent::Member))
      # puis les 3 tables qui découlent de Adherent::Member
      create_function(sql_copy_one_ref('member_id', 'adherent_payments',
        champ:Adherent::Member, modele:Adherent::Payment))
      create_function(sql_copy_one_ref('member_id', 'adherent_coords',
        champ:Adherent::Member, modele:Adherent::Coord))
      create_function(sql_copy_one_ref('member_id', 'adherent_adhesions',
        champ:Adherent::Member, modele:Adherent::Adhesion))
      create_function(sql_copy_n_refs('payment_id', ['adhesion_id'],
             'adherent_reglements', {champ:Adherent::Payment,
             adhesion_id:Adherent::Adhesion,
             modele:Adherent::Reglement}))
    end

    def quote_string(s)
      return unless s
      s.gsub(/\\/, '\&\&').gsub(/'/, "''")
    end


    def self.create_function(sql)
      Organism.find_by_sql(sql)
    end

    # Méthodes ayant pour effet de fournir des textes SQL pour création des
    # fonctions nécessaires à la copie des données.
    #
    # sql_copy_first traite les descendants directs de Organism tels
    # Sector, Period, Nomenclature, et Adherent::Member
    #
    # Les arguments sont le nom de la table (par exemple sectors), et
    # éventuellement une option pour préciser le modèle,
    # ce qui est nécessaire lorsqu'il n'est pas
    # possible de récupérer le nom du modèle par la table (cas des
    # Adherent::Members par exemple, on écrira alors en options
    # :modele=>Adherent::Member)
    def self.sql_copy_first_level(table, options={})
      sql_copy_n_refs('organism_id', [], table, options)
    end



    # Réalise des copies des enregistrements
    # d'une table (argument table) faisant référence à un
    # champ (champ_id) d'une autre table. La différence avec la méthode
    # précédente est juste que organism_id n'est pas le champ_id par défaut.
    #
    # Voir les commentaires de sql_copy_n_refs pour les arguments table et
    # les options
    #
    # Exemple d'utilisation : sql_copy_one_ref('cash_id', 'cash_controls')
    #
    def self.sql_copy_one_ref(champ_id, table, options={})
      sql_copy_n_refs(champ_id, [], table, options)
    end

    # Réalise des copies des enregistrements
    # d'une table (argument table) faisant référence à un champ principal
    # (champ_id) et une série de champs secondaires (sous le format champ_id)
    # qui devront être mis à jour simultanément.
    #
    # Ainsi, le premier champ est le champ de référence (par exemple
    # pour Account, c'est period_id),
    # le second champ est un array de champs qui doivent
    # être mis à jour (pour Account, c'est [sector_id])
    #
    # Pour des compta_lines, le champ principal est writing_id, tandis que le
    # tableau des autres champs sera [destination_id, account_id, nature_id,
    # check_deposit_id].
    #
    # Il est possible de fournir un array vide []
    #
    # Exemple d'utilisation :
    # sql_copy_n_refs('writing_id', ['nature_id', 'destination_id',
    # 'account_id', 'check_deposit_id], 'compta_lines')
    #
    # La méthode renvoie un texte sql qui peut alors être utilisé pour créer
    # dans la base la fonction de recopie.
    #
    # Les options sont un hash facultatif permettant de préciser
    #  - le modèle à traiter lorsqu'il ne peut être déduit du nom de la table
    #  C'est typiquement le cas pour la famille des tables adherent_members
    #  qui fait référence à Adherent::Member. Dans ce cas, on précise dans les
    #  options :modele=>Adherent::Member
    #  - le nom du champ lorsqu'il ne peut être déduit de champ_ids, le seul
    #  cas actuellement étant bridge_id qui fait référence à un
    #  Adherent::Member. Dans ce cas, on mettra dans les options
    #  :bridge_id=>Adherent::Member
    #
    #
    def self.sql_copy_n_refs(champ_id, champ_ids, table, options= {})

      # on définit ici les variables dont on aura besoin dans le texte sql
      nom_fonction = 'copy_' + table

      begin
        modele = options[:modele] || table.classify.constantize
      rescue NameError
        raise NameError, 'Impossible d\'identifier le modèle ;
vous devez le fournir en deuxième argument'
      end

      # le nom du modèle que l'on cherchera dans la table flc_cloner
      champ = champ_to_search(champ_id, options[:champ])
      # récupération de tous les champs dont on assure la recopie à l'identique
      # ne sont donc pas recopiés le champ id, et les arguments  champ_ids
      list_cols = modele.column_names
      list_cols = list_cols.reject { |c| c == 'id' || c == champ_id ||
            c.in?(champ_ids) }
      list  = list_cols.join(', ')
      r_list = list_cols.map { |c| 'r."'+c+'"'}.join(', ')

      list_champ = champ_ids.join(', ')
      # construction des requêtes cherchant les valeurs dans la table
      # flc_cloner
      values = champ_ids.collect do |cid|
        mod = options[cid.to_sym].to_s
        if options[:polymorphic] == cid
          value_to_insert(cid, mod, polymorphic:true)
        else
          value_to_insert(cid, mod)
        end
      end.join(', ')


      sql = <<-EOF
   CREATE OR REPLACE FUNCTION #{nom_fonction}(from_id integer, to_id integer)
   RETURNS SETOF #{table} AS
$BODY$
DECLARE
  r RECORD;
  new_id int;
BEGIN
  FOR r in SELECT * FROM #{table} WHERE #{champ_id} IN (
    SELECT old_id FROM flccloner WHERE name = #{champ} AND old_org_id = from_id
      AND new_org_id = to_id
)

  LOOP
    WITH  correspondance AS
    ( INSERT INTO #{table}
       (#{champ_id},
        #{ list_champ + ', ' unless list_champ.empty?}
        #{list})
      VALUES (#{value_to_insert(champ_id, options[:champ])},
      #{values + ', ' unless values.empty?}
      #{r_list})
     RETURNING id, r.id  oldid)
      INSERT INTO flccloner (name, old_id, new_id, old_org_id, new_org_id)
      VALUES ('#{modele}', r.id,
      (SELECT id FROM correspondance WHERE oldid = r.id ), from_id, to_id);
    RETURN NEXT r;
  END LOOP;
  RETURN;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
      EOF

      sql
    end

    def self.create_refill_check_deposit_function
      sql = <<-EOF
CREATE OR REPLACE FUNCTION refill_check_deposits(from_id integer, to_id integer)
  RETURNS SETOF check_deposits AS
$BODY$
DECLARE
  r RECORD;
BEGIN
FOR r in EXECUTE format('SELECT * FROM compta_lines WHERE check_deposit_id IN (
    SELECT old_id FROM flccloner
    WHERE name = %L AND old_org_id = %L AND new_org_id = %L)', 'CheckDeposit',
    from_id, to_id)

  LOOP

    UPDATE compta_lines SET check_deposit_id = (SELECT flccloner.new_id FROM flccloner
           WHERE name = 'CheckDeposit'
           AND flccloner.old_id = r.check_deposit_id
           AND old_org_id = from_id AND new_org_id = to_id) WHERE
           compta_lines.id = (SELECT flccloner.new_id FROM flccloner
           WHERE name = 'ComptaLine'
           AND flccloner.old_id = r.id
           AND old_org_id = from_id AND new_org_id = to_id);

  END LOOP;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
EOF
      create_function(sql)
    end

    # Pour les Writings, la transformation fait perdre le bridge_id lorsque
    # le bridge_type est Mask.
    # Pour cette classe, on va donc créer une fonction spécifique qui ne fait
    # que transformer le champ bridge_id.
    #
    # Le principe est de prendre tous les Writings qui sont référencés
    # dans la table flc_cloner, puis seulement celle qui ont le champ
    # bridge_type rempli avec 'Mask'; et pour celles-ci de faire un update
    # de bridge_id avec l'id du Mask que l'on va aller chercher dans flc_cloner
    #
    # On veut toutes les writings qui sont dans flc_cloner avec to_id qui nous
    # est fourni
    #
    def self.create_clone_fill_bridge_id
      sql = <<-EOF
        CREATE OR REPLACE FUNCTION clone_fill_bridge_id(from_id integer, to_id integer)
        RETURNS SETOF writings AS
        $BODY$
        DECLARE
          r RECORD;
        BEGIN
FOR r in EXECUTE format('SELECT * FROM writings WHERE writings.id IN (
    SELECT id FROM flccloner
    WHERE name = %L AND old_org_id = %L AND new_org_id = %L AND
    writings.bridge_type = %L)', 'Writing',
    from_id, to_id, 'Mask')
LOOP
UPDATE writings SET bridge_id = (SELECT new_id FROM flccloner WHERE
      name = 'Mask' AND new_org_id = to_id AND old_org_id = from_id
      AND old_id = r.bridge_id)

WHERE writings.id = (SELECT new_id FROM flccloner WHERE name = 'Writing'
  AND flccloner.old_id = r.id AND new_org_id = to_id AND old_org_id = from_id);
END LOOP;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
EOF
      create_function(sql)
    end

    protected

    # Définit le morceau de requête qui permet de trouver dans la table# flccloner la valeur souhaitée pour mettre à jour les références.
    #
    # Le deuxième champ permet de préciser le nom du modèle lorsqu'il ne
    # peut être déduit de champ_id. C'est notamment le cas pour
    # la table des Writing dont le champ bridge_id fait référence à
    # Adherent::Member
    #
    # On peut précisier via le hash options si le champ est polymorphique
    def self.value_to_insert(champ_id, champ = nil, options={})
      raise ArgumentError, 'L\'argument doit être de la forme wwww_id' unless
      champ_id =~ /.*_id$/
      champname = champ_to_search(champ_id, champ, options)
      "(SELECT flccloner.new_id FROM flccloner
           WHERE name = #{champname}
           AND flccloner.old_id = r.#{champ_id}
           AND old_org_id = from_id AND new_org_id = to_id)"
    end

    # trouve le nom du champ à rechercher dans la table de correspondance
    # des id (flccloner).
    # Si le champ est polymorphique (cas dans la table Account des
    # BankAccount et Cash (ce qui donne accountable_type et accountable_id)
    def self.champ_to_search(champ_id, champ, options={})

      if options[:polymorphic]
        s =champ_id[0..-4]+'_type'
        s = "r.#{s}"
      else
        s = champ.blank? ? champ_id[0..-4].classify : champ
        s = "'#{s}'"
      end
      return s

    end

  end
end
