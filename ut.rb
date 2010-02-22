#!/usr/bin/env ruby
require 'rubygems'
require 'pubmed'
require 'mongo_mapper'

MongoMapper.database = 'utpub'

class MeshTerm
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :qualifier, String
  key :name_with_qualifier, String
  key :is_major, Boolean
  
#  before_save :update_name_with_qualifier

#  def update_name_with_qualifier
#    unless self.qualifier == '' or self.qualifier == nil
#      self.name_with_qualifier = "#{name}/#{qualifier}"
#    else
#      self.name_with_qualifier = name
#    end
#  end
end

class Journal
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :name_abbrv, String
  key :issn_online, String
  key :issn_print, String
  key :nlm_unique_id, String
end

class Article
  include MongoMapper::Document
  
  key :pmid, String
  key :title, String  
  key :authors, Array
  key :affiliation, String
  key :abstract, String
  key :abstract_copyright, String
  key :pubmed_status, String
  key :medline_status, String
  key :pages, String
  key :volume, String
  key :issue, String
  key :medline_date, String 
  key :pubdate_year, String 
  key :pubdate_month, String 
  key :pubdate_day, String 
  key :pubdate, String 
  
  key :journal
  many :mesh_terms
  
  key :raw, String
  timestamps!
end

if $0 == __FILE__
  entrez = PubMed::Entrez.new 'mattgrayson@uthsc.edu'  
  results = entrez.search 'lung cancer radiotherapy review', true, {:retmax => 50}
  articles = results[:articles]
  articles.each do |a|
    pub = Article.first_or_create(:pmid => a[:pmid])
    if pub.raw != a[:raw]
      puts "Creating/updating document #{a[:pmid]}"
      pub.classifications.clear
      a[:subjects].each do |s|
        term = MeshTerm.first_or_create(:name => s[:name], :qualifier => s[:qualifier])
        pub.classifications << Classification.new(:mesh_term => term, :is_major => s[:is_major])
      end
      a.delete(:subjects)
      
      j = Journal.first_or_create(:nlm_unique_id => a[:journal][:nlm_unique_id])
      j.update_attributes(a[:journal])
      j.save
      pub.journal = j
      a.delete(:journal)
      
      pub.update_attributes(a)
    else
      puts "No changes for #{a[:pmid]}"
    end
  end
end

#QUERY = '"ut memphis"[Affiliation] 
#OR ("ut"[Affiliation] AND "memphis"[Affiliation]) 
#OR ("ut health science center"[Affiliation] AND "tennessee"[Affiliation]) 
#OR ("ut health science center"[Affiliation] AND "memphis"[Affiliation]) 
#OR ("ut health sciences center"[Affiliation] AND "tennessee"[Affiliation]) 
#OR ("ut health sciences center"[Affiliation] AND "memphis"[Affiliation]) 
#OR (ut health sci*[Affiliation] AND "memphis"[Affiliation]) 
#OR (university of tennessee health sci*[Affiliation] AND "memphis"[Affiliation]) 
#OR "university of tennessee memphis"[Affiliation] 
#OR ("university of tennessee"[Affiliation] AND "memphis"[Affiliation]) 
#OR "university of tennessee health science center"[Affiliation] 
#OR "university of tennessee health sciences center"[Affiliation] 
#OR "university of tennessee college of medicine"[Affiliation] 
#OR ("ut college of medicine"[Affiliation] AND "memphis"[Affiliation]) 
#OR ("ut college of medicine"[Affiliation] AND "tennessee"[Affiliation]) 
#OR ("utmem"[Affiliation] AND "tennessee"[Affiliation]) 
#OR ("uthsc"[Affiliation] AND "tennessee"[Affiliation])'
#
#entrez = PubMed::Entrez.new 'test'
#results= entrez.search QUERY, true, {:retmax => 10}
#results[:articles].each do |a|
#  puts a[:pmid]
#  puts a[:affiliation]
#  puts a[:title]
#  a[:subjects].each do |s|    
#    puts "- #{s[:name]}"
#  end
#  puts '-'*100
#end
