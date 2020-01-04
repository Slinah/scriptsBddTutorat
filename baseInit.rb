#!/usr/bin/ruby
# frozen_string_literal: true

class BaseV1
  def init
    @host = 'localhost'
    @database = 'tutorat'
    @user = 'root'
    @pass = ''
  end

  attr_reader :host

  attr_reader :database

  attr_reader :user

  attr_reader :pass
end


# Init base
class BaseV2
  def init
    @host = 'localhost'
    @database = 'tutoratrefonte'
    @user = 'root'
    @pass = ''
  end
  attr_reader :host

  attr_reader :database

  attr_reader :user

  attr_reader :pass
end