#!/usr/bin/ruby
# frozen_string_literal: true


def convertBytesToInt(bit)
  if bit.bytes.to_a[0] == 0
    0
  elsif bit.bytes.to_a[0] == 1
    1
  elsif bit.bytes.to_a[0] == 2
    2
  end
end


def fixPromosNames(promo)
  if promo == 'WIS 1'
    promo = 'Wis1'
  elsif promo == 'WIS 2'
    promo = 'Wis2'
  elsif promo == 'WIS 3'
    promo = 'Wis3'
  end
  promo
end