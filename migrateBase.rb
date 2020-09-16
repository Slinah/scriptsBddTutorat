#!/usr/bin/ruby
# frozen_string_literal: true

require 'mysql2'
require 'securerandom'
load './baseInit.rb'
load './regexEncode.rb'
load './fixErrors.rb'

Entry = BaseV1.new
Entry.init
OpenConnectEntry = Mysql2::Client.new(host: Entry.host,
                                      database: Entry.database,
                                      user: Entry.user)

Sortie = BaseV2.new
Sortie.init
OpenConnectSortie = Mysql2::Client.new(host: Sortie.host,
                                       database: Sortie.database,
                                       user: Sortie.user)

uuid = -> { return SecureRandom.uuid.upcase }

# Checked
# Migrate Personne
query = OpenConnectEntry.query('SELECT nom, prenom, role, mdp, mail, classe, promo FROM personne p JOIN classe c ON p.id_classe=c.id_classe JOIN promo pr ON c.id_promo=pr.id_promo')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_classe FROM classe c JOIN promo p ON c.id_promo=p.id_promo WHERE c.intitule = ? AND p.intitule = ?')
  query2 = query2.execute(row['classe'], fixPromosNames(row['promo']))
  query2.each do |row2|
    response = OpenConnectSortie.prepare('INSERT INTO personne(id_personne, id_classe, nom, prenom, role, password, mail, token, image) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?)')
    response.execute(uuid.call, row2['id_classe'], regexEncode(row['nom']).upcase, regexEncode(row['prenom']), convertBytesToInt(row['role']), row['mdp'], row['mail'], nil, nil)
  end
  puts "Exec for PERSONNE => #{idx}"
end
puts '--- Exec ended for Personne'

# Checked
# Migrate Matiere
query = OpenConnectEntry.query('SELECT intitule FROM matiere')
query.each_with_index do |row, idx|
  response = OpenConnectSortie.prepare('INSERT INTO matiere(id_matiere, intitule, validationAdmin) VALUES ( ?, ?, ?)')
  response.execute(uuid.call, regexEncode(row['intitule']), 1)
  puts "Exec for MATIERE => #{idx}"
end
puts '--- Exec ended for Matiere'

# Checked
# Migrate Cours
query = OpenConnectEntry.query('SELECT c.id_cours AS id_cours, c.intitule AS intitule, c.heure AS heure, c.date AS date, c.commentaires AS commentaires, c.nbParticipants AS participants, c.duree AS duree, c.status AS status, c.secu AS secu, m.intitule AS matiere FROM cours c JOIN matiere m ON c.id_matiere=m.id_matiere ORDER BY c.date')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_matiere FROM matiere WHERE intitule = ?')
  query2 = query2.execute(row['matiere'])
  query2.each do |row2|
    query3 = OpenConnectEntry.prepare('SELECT id_promo FROM cours_promo WHERE id_cours = ?')
    query3 = query3.execute(row['id_cours'])
    query3.each do |row3|
      query4 = OpenConnectEntry.prepare('SELECT promo FROM promo WHERE id_promo = ?')
      query4 = query4.execute(row3['id_promo'])
      query4.each do |row4|
        query5 = OpenConnectSortie.prepare('SELECT id_promo FROM promo WHERE intitule = ?')
        query5 = query5.execute(fixPromosNames(row4['promo']))
        query5.each do |row5|

          # puts type(row['heure']), type(row['date'])
          response = OpenConnectSortie.prepare('INSERT INTO `cours`(`id_cours`, `id_matiere`, `id_promo`, `intitule`, `date`, `commentaires`, `nbParticipants`, `duree`, `status`, `stage`, `salle`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
          response.execute(uuid.call, row2['id_matiere'], row5['id_promo'], regexEncode(row['intitule']),  DateTime.parse("#{row['date']} #{row['heure']}"), regexEncode(row['commentaires']), row['participants'], row['duree'], convertBytesToInt(row['status']), 0, nil)
        end
      end
    end
  end
  puts "Exec for COURS => #{idx}"
end
puts '--- Exec ended for Cours'

# Checked
# Migrate Personne_Cours
query = OpenConnectEntry.query('SELECT c.intitule AS intitule, c.date AS date, p.mdp AS mdp, p.mail AS mail, pc.rang_personne AS rang_personne FROM cours c JOIN personne_cours pc ON c.id_cours = pc.id_cours JOIN personne p ON pc.id_personne = p.id_personne')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_personne FROM personne WHERE mail = ? AND password = ?')
  query2 = query2.execute(row['mail'], row['mdp'])
  query2.each do |row2|
    query3 = OpenConnectSortie.prepare('SELECT id_cours FROM cours WHERE intitule = ?')
    query3 = query3.execute(row['intitule'])
    query3.each do |row3|
      response = OpenConnectSortie.prepare('INSERT INTO personne_cours(id_personne, id_cours, rang_personne) VALUES (?, ?, ?)')
      response.execute(row2['id_personne'], row3['id_cours'], convertBytesToInt(row['rang_personne']))
    end
  end
  puts "Exec for PERSONNE_COURS => #{idx}"
end
puts '--- Exec ended for Personne_Cours'

# Checked
# Migrate Proposition
query = OpenConnectEntry.query('SELECT m.intitule AS matiere FROM proposition p JOIN matiere m ON p.id_matiere = m.id_matiere')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_matiere FROM matiere WHERE intitule = ?')
  query2 = query2.execute(row['matiere'])
  query2.each do |row2|
    response = OpenConnectSortie.prepare('INSERT INTO proposition(id_proposition, id_createur, id_matiere) VALUES (?, ?, ?)')
    response.execute(uuid.call, nil, row2['id_matiere'])
  end
  puts "Exec for PROPOSITION => #{idx}"
end
puts '--- Exec ended for Proposition'

# Checked
# Migrate Proposition_Promo
query = OpenConnectEntry.query('SELECT m.intitule AS matiere, po.promo AS promo FROM proposition p JOIN promo po ON p.id_promo=po.id_promo JOIN matiere m ON p.id_matiere=m.id_matiere')
query.each_with_index do |row, idx|
  query4 = OpenConnectSortie.prepare('SELECT id_matiere FROM matiere WHERE intitule = ?')
  query4 = query4.execute(row['matiere'])
  query4.each do |row4|
    query2 = OpenConnectSortie.prepare('SELECT id_proposition FROM proposition WHERE id_matiere = ?')
    query2 = query2.execute(row4['id_matiere'])
    query2.each do |row2|
      query3 = OpenConnectSortie.prepare('SELECT id_promo FROM promo WHERE intitule = ?')
      query3 = query3.execute(fixPromosNames(row['promo']))
      query3.each do |row3|
        response = OpenConnectSortie.prepare('INSERT INTO proposition_promo(id_proposition, id_promo) VALUES (?, ?)')
        response.execute(row2['id_proposition'], row3['id_promo'])
      end
    end
  end
  puts "Exec for PROPOSITION_PROMO => #{idx}"
end
puts '--- Exec ended for Proposition_Promo'

# Checked
# Migrate Personne_Proposition
query = OpenConnectEntry.query('SELECT m.intitule AS matiere, p.mdp AS mdp, p.mail AS mail FROM personne p JOIN personne_proposition pp ON p.id_personne=pp.id_personne JOIN proposition po ON pp.id_proposition=po.id_proposition JOIN matiere m ON po.id_matiere=m.id_matiere')
query.each_with_index do |row, idx|
  query4 = OpenConnectSortie.prepare('SELECT id_matiere FROM matiere WHERE intitule = ?')
  query4 = query4.execute(row['matiere'])
  query4.each do |row4|
    query2 = OpenConnectSortie.prepare('SELECT id_proposition FROM proposition WHERE id_matiere = ?')
    query2 = query2.execute(row4['id_matiere'])
    query2.each do |row2|
      query3 = OpenConnectSortie.prepare('SELECT id_personne FROM personne WHERE mail = ? AND password = ?')
      query3 = query3.execute(row['mail'], row['mdp'])
      query3.each do |row3|
        response = OpenConnectSortie.prepare('INSERT INTO personne_proposition(id_personne, id_proposition) VALUES (?, ?)')
        response.execute(row3['id_personne'], row2['id_proposition'])
      end
    end
  end
  puts "Exec for PERSONNE_PROPOSITION => #{idx}"
end
puts '--- Exec ended for Personne_proposition'