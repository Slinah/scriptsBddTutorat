#!/usr/bin/ruby
# frozen_string_literal: true

require 'mysql2'
require 'securerandom'
load './baseInit.rb'
load './regexEncode.rb'

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

# Migrate Personne
query = OpenConnectEntry.query('SELECT nom, prenom, role, mdp, mail, classe, promo FROM personne p JOIN classe c ON p.id_classe=c.id_classe JOIN promo pr ON c.id_promo=pr.id_promo')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_classe FROM classe c JOIN promo p ON c.id_promo=p.id_promo WHERE classe = ? AND promo = ?')
  query2 = query2.execute(row['classe'], row['promo'])
  query2.each do |row2|
    response = OpenConnectSortie.prepare('INSERT INTO personne(id_personne, nom, prenom, role, mdp, mail, id_classe) VALUES ( ?, ?, ?, ?, ?, ?, ?)')
    response.execute(uuid.call, regexEncode(row['nom']).upcase, regexEncode(row['prenom']), row['role'], row['mdp'], row['mail'], row2['id_classe'])
  end
  puts "Exec for PERSONNE => #{idx}"
end

# Migrate Matiere
query = OpenConnectEntry.query('SELECT * FROM matiere')
query.each_with_index do |row, idx|
  response = OpenConnectSortie.prepare('INSERT INTO matiere(id_matiere, intitule) VALUES ( ?, ?)')
  response.execute(uuid.call, regexEncode(row['intitule']))
  puts "Exec for MATIERE => #{idx}"
end

# Migrate Cours
query = OpenConnectEntry.query('SELECT c.intitule AS intitule, c.heure AS heure, c.date AS date, c.commentaires AS commentaires, c.nbInscrits as inscrits, c.nbParticipants AS participants, c.duree AS duree, c.status AS status, c.secu AS secu, m.intitule AS matiere FROM cours c JOIN matiere m ON c.id_matiere=m.id_matiere')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_matiere FROM matiere WHERE intitule = ?')
  query2 = query2.execute(row['matiere'])
  query2.each do |row2|
    response = OpenConnectSortie.prepare('INSERT INTO cours(id_cours, intitule, heure, date, commentaires, nbInscrits, nbParticipants, duree, status, secu, id_matiere) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
    response.execute(uuid.call, regexEncode(row['intitule']), row['heure'], row['date'], regexEncode(row['commentaires']), row['inscrits'], row['participants'], row['duree'], row['status'], row['secu'], row2['id_matiere'])
  end
  puts "Exec for COURS => #{idx}"
end

# Migrate Cours_Promo
query = OpenConnectEntry.query 'SELECT c.secu AS secu, p.promo AS promo FROM cours c JOIN cours_promo pc ON c.id_cours = pc.id_cours JOIN promo p ON pc.id_promo = p.id_promo'
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_promo FROM promo WHERE promo = ?')
  query2 = query2.execute(row['promo'])
  query2.each do |row2|
    query3 = OpenConnectSortie.prepare('SELECT id_cours FROM cours WHERE  secu = ?')
    query3 = query3.execute(row['secu'])
    query3.each do |row3|
      query4 = OpenConnectSortie.prepare('INSERT INTO cours_promo(id_cours, id_promo) VALUES ( ?, ?)')
      query4.execute(row3['id_cours'], row2['id_promo'])
    end
  end
  puts "Exec for COURS_PROMO => #{idx}"
end

# Migrate Personne_Cours
query = OpenConnectEntry.query('SELECT c.secu AS secu, p.mdp AS mdp, p.mail AS mail, pc.rang_personne AS rang_personne FROM cours c JOIN personne_cours pc ON c.id_cours = pc.id_cours JOIN personne p ON pc.id_personne = p.id_personne')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_personne FROM personne WHERE mail = ? AND mdp = ?')
  query2 = query2.execute(row['mail'], row['mdp'])
  query2.each do |row2|
    query3 = OpenConnectSortie.prepare('SELECT id_cours FROM cours WHERE secu = ?')
    query3 = query3.execute(row['secu'])
    query3.each do |row3|
      response = OpenConnectSortie.prepare('INSERT INTO personne_cours(id_personne, id_cours, rang_personne) VALUES (?, ?, ?)')
      response.execute(row2['id_personne'], row3['id_cours'], row['rang_personne'])
    end
  end
  puts "Exec for PERSONNE_COURS => #{idx}"
end

# Migrate Proposition
query = OpenConnectEntry.query('SELECT m.intitule AS matiere, p.secu AS secu FROM proposition p JOIN matiere m ON p.id_matiere = m.id_matiere')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_matiere FROM matiere WHERE intitule = ?')
  query2 = query2.execute(row['matiere'])
  query2.each do |row2|
    response = OpenConnectSortie.prepare('INSERT INTO proposition(id_proposition, id_matiere, secu) VALUES (?, ?, ?)')
    response.execute(uuid.call, row2['id_matiere'], row['secu'])
  end
  puts "Exec for PROPOSITION => #{idx}"
end

# Migrate Proposition_Promo
query = OpenConnectEntry.query('SELECT p.secu AS secu, po.promo AS promo FROM proposition p JOIN promo po ON p.id_promo=po.id_promo')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_proposition FROM proposition WHERE secu = ?')
  query2 = query2.execute(row['secu'])
  query2.each do |row2|
    query3 = OpenConnectSortie.prepare('SELECT id_promo FROM promo WHERE promo = ?')
    query3 = query3.execute(row['promo'])
    query3.each do |row3|
      response = OpenConnectSortie.prepare('INSERT INTO proposition_promo(id_proposition, id_promo) VALUES (?, ?)')
      response.execute(row2['id_proposition'], row3['id_promo'])
    end
  end
  puts "Exec for PROPOSITION_PROMO => #{idx}"
end

# Migrate Personne_Proposition
query = OpenConnectEntry.query('SELECT po.secu AS secu, p.mdp AS mdp, p.mail AS mail FROM personne p JOIN personne_proposition pp ON p.id_personne=pp.id_personne JOIN proposition po ON pp.id_proposition=po.id_proposition')
query.each_with_index do |row, idx|
  query2 = OpenConnectSortie.prepare('SELECT id_proposition FROM proposition WHERE secu = ?')
  query2 = query2.execute(row['secu'])
  query2.each do |row2|
    query3 = OpenConnectSortie.prepare('SELECT id_personne FROM personne WHERE mail = ? AND mdp = ?')
    query3 = query3.execute(row['mail'], row['mdp'])
    query3.each do |row3|
      response = OpenConnectSortie.prepare('INSERT INTO personne_proposition(id_personne, id_proposition) VALUES (?, ?)')
      response.execute(row3['id_personne'], row2['id_proposition'])
    end
  end
  puts "Exec for PERSONNE_PROPOSITION => #{idx}"
end
