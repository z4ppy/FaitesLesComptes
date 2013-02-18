# coding: utf-8


# sans accent pour éviter les problèmes d'affichage sous windows
if Rails.env == 'ocra'
  puts ''
  puts "=== Fin de l'etape 1"
  puts ''

  puts "=== Lancement de l'etape 2 : demarrage du serveur"
  puts "Lorsque vous verrez les trois prochaines lignes, le serveur sera lance et vous pourrez utiliser votre navigateur prefere (Firefox, Chrome, Internet Explorer,...) a l'adresse localhost:3000."
else
  puts 'Bienvenue sur FaitesLesComptes, le logiciel open_source de comptabilité de trésorerie'
end