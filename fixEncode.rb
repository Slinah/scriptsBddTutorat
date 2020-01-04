#!/usr/bin/ruby
# frozen_string_literal: true

require 'mysql2'
load './baseInit.rb'
load './regexEncode.rb'


db = BaseV1.new
db.init
ct = Mysql2::Client.new(host: db.host,
                        database: db.database,
                        user: db.user)

q = ct.query('SELECT nom, prenom, id_personne FROM personne')
q.each_with_index do |r, i|
  u = ct.prepare('UPDATE personne SET nom = ?, prenom = ? WHERE id_personne = ?')
  u.execute(regexEncode(r['nom']), regexEncode(r['prenom']), r['id_personne'])
  puts "Exec personne #{i}"
end

q = ct.query('SELECT intitule, id_matiere FROM matiere')
q.each_with_index do |r, i|
  u = ct.prepare('UPDATE matiere SET intitule = ? WHERE id_matiere = ?')
  u.execute(regexEncode(r['intitule']), r['id_matiere'])
  puts "Exec matiere #{i}"
end

q = ct.query('SELECT intitule, commentaires, id_cours FROM cours')
q.each_with_index do |r, i|
  u = ct.prepare('UPDATE cours SET intitule = ?, commentaires = ? WHERE id_cours = ?')
  u.execute(regexEncode(r['intitule']), regexEncode(r['commentaires']), r['id_cours'])
  puts "Exec cours #{i}"
end