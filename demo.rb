#!/usr/bin/env ruby
require 'rubygems'
require 'lib/pubmed'

def print_citation(cite)
  puts cite[:citation]
  puts cite[:pmid]
  puts cite[:title]
  puts cite[:pubdate_str]
  puts cite[:pubdate]
  puts cite[:authors]
  puts cite[:subjects]
end

if $0 == __FILE__
  pm = PubMed::Entrez.new 'test'
  
  QUERY = '"ut memphis"[Affiliation] 
  OR ("ut"[Affiliation] AND "memphis"[Affiliation]) 
  OR ("ut health science center"[Affiliation] AND "tennessee"[Affiliation]) 
  OR ("ut health science center"[Affiliation] AND "memphis"[Affiliation]) 
  OR ("ut health sciences center"[Affiliation] AND "tennessee"[Affiliation]) 
  OR ("ut health sciences center"[Affiliation] AND "memphis"[Affiliation]) 
  OR (ut health sci*[Affiliation] AND "memphis"[Affiliation]) 
  OR (university of tennessee health sci*[Affiliation] AND "memphis"[Affiliation]) 
  OR "university of tennessee memphis"[Affiliation] 
  OR ("university of tennessee"[Affiliation] AND "memphis"[Affiliation]) 
  OR "university of tennessee health science center"[Affiliation] 
  OR "university of tennessee health sciences center"[Affiliation] 
  OR "university of tennessee college of medicine"[Affiliation] 
  OR ("ut college of medicine"[Affiliation] AND "memphis"[Affiliation]) 
  OR ("ut college of medicine"[Affiliation] AND "tennessee"[Affiliation]) 
  OR ("utmem"[Affiliation] AND "tennessee"[Affiliation]) 
  OR ("uthsc"[Affiliation] AND "tennessee"[Affiliation])'
  
  if ARGV.length == 0
    results = pm.search QUERY, true, {:retmax => 25}
  elsif ARGV.length == 1
    results = pm.search "#{ARGV[0]}[uid]", true, {:retmax => 1}
  end
  
  results[:articles].each do |a|
    print_citation a
    puts '-'*50
  end
end
