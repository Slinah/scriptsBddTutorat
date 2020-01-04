#!/usr/bin/ruby
# frozen_string_literal: true

def regexEncode(encoded)
  return nil if encoded.nil?

  result = if encoded.match('&eacute;') || encoded.match('Ã©')
             flag = nil
             encoded.sub!('&eacute;', "\xC3\xA9")
           elsif encoded.match('&euml;') || encoded.match('Ã«')
             flag = nil
             encoded.sub!('&euml;', "\xC3\xAB")
           elsif encoded.match('&egrave;') || encoded.match('Ã¨')
             flag = nil
             encoded.sub!('&egrave;', "\xC3\xA8")
           elsif encoded.match('&agrave;') || encoded.match('Ã')
             flag = nil
             encoded.sub!('&agrave;', "\xC3\xA0")
           elsif encoded.match('&ccedil;') || encoded.match('Ã§')
             flag = nil
             encoded.sub!('&ccedil;', 'ç')
           elsif encoded.match('&ugrave;') || encoded.match('Ã¹')
             flag = nil
             encoded.sub!('&ugrave;', 'ù')
           else
             flag = 0
             encoded
           end
  flag.nil? ? regexEncode(result) : result
end
