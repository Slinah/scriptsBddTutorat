#!/usr/bin/ruby
# frozen_string_literal: true

require 'mysql2'
require 'securerandom'
load './baseInit.rb'



bdd = BaseV2.new
bdd.init
c = Mysql2::Client.new(host: Entry.host,
                       database: Entry.database,
                       user: Entry.user)

qc = c.query('SELECT id_cours, date, commentaires, nbParticipants, duree, id_matiere FROM cours')