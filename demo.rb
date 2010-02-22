#!/usr/bin/env ruby
require 'rubygems'
require 'lib/pubmed'

if $0 == __FILE__
  pm = PubMed::Entrez.new 'test'
  
  if ARGV.length == 1
    results = pm.search "#{ARGV[0]}[uid]", true, {:retmax => 1}
    puts results[:articles][0][:pmid]
    puts results[:articles][0][:title]
    puts results[:articles][0][:pubdate]
    puts results[:articles][0][:authors]
    puts results[:articles][0][:subjects]
  end
end
