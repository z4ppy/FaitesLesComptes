# Admin::VersionController est destiné à permettre la mise à jour des versions
# lorsque l'on change de version de logiciel ou lorsqu'on importe une base
# qui a été créée dans une version antérieure.
#
# Il y a donc deux cas de figure, le premier, correspondant à l'action migrate
# est destiné à traiter le cas où on démarre le logiciel avec une version
# plus récente.
#
# Il faut donc migrer toutes les bases de données : rooms et les autres
#
# Le second cas est lorsqu'on importe une base de données qui est dans une version
# antérieure. Ce cas est détecté par le restore_controller
#
class Admin::VersionsController < ApplicationController

  skip_before_filter :control_version
  skip_before_filter :log_in?


  # GET new pour demander si on veut effectivement faire migrer les bases de données
  def new

  end

  # POST migrate_each pour migrer l'ensemble des bases de données
  def migrate_each
    Room.migrate_each # migre Room et les différentes bases
    Rails.cache.clear('version_update')
    redirect_to admin_organisms_url
  end

end