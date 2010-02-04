#!/usr/bin/env ruby
require 'rest-client'
require 'nokogiri'

module PubMed
  class Entrez
    
    attr_accessor :search_results, :last_query, :email_address, :search_uri, :fetch_uri
    
    ENTREZ_BASE_URI = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/'
    
    
    def initialize(email)
      @search_results = ''
      @last_query = ''
      @email_address = email
      @search_uri = "#{@ENTREZ_BASE_URI}/esearch.fcgi?db=pubmed&retmode=xml&usehistory=y&email=#{email}"
      @fetch_uri = "#{@ENTREZ_BASE_URI}/efetch.fcgi?db=pubmed&retmode=xml&rettype=full&email=#{email}"
      @conn = ''
    end
    
  end
end