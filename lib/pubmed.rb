#!/usr/bin/env ruby
require 'httparty'
require 'nokogiri'

module PubMed
  class Entrez
    
    include HTTParty
    base_uri 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/'

    class Parser::NokogiriXML < HTTParty::Parser
      def parse
        {:raw => body, :parsed => Nokogiri.parse(body)}
      end
    end
    parser Parser::NokogiriXML
    
    attr_accessor :search_results, :last_query, :email_address, :search_uri
    
    def initialize(email)
      @search_results = ''
      @last_query = ''
      @email_address = email
      @search_uri = '/esearch.fcgi'
      @fetch_uri = '/efetch.fcgi'
    end
    
    def search(query, options={}, autofetch=false)
      query_options = {
        :db => 'pubmed',
        :retmode => 'xml',
        :usehistory => 'y',
        :email => @email_address,
        :term => query
      }.update(options)
      response = self.class.get(@search_uri, :query => query_options)
      doc = response[:parsed]
      results = {
        :total_found => doc.xpath(".//eSearchResult/Count").text,
        :query_key => doc.xpath(".//eSearchResult/QueryKey").text,
        :web_env => doc.xpath(".//eSearchResult/WebEnv").text
      }
      if autofetch
        total = options.has_key?(:retmax) ? options[:retmax] : results[:total_found]
        results[:articles] = fetch_search_results(
          results[:web_env], 
          results[:query_key], 
          total
        )
      else
        results[:pmids] = doc.xpath('.//eSearchResult/IdList/Id').collect(&:text)
      end
      results
    end
    
    def fetch_search_results(web_env, query_key, total)
      articles = []
      query_options = {
        :db => 'pubmed',
        :retmode => 'xml',
        :rettype => 'full',
        :email => @email_address,
        :WebEnv => web_env,
        :query_key => query_key,
        :retstart => 0,
        :retmax => total < 500 ? total : 500
      }
      while query_options[:retstart] < total:
        puts "Fetching results #{query_options[:retstart]} - #{query_options[:retstart]+query_options[:retmax]} ..."
        results = self.class.get(@fetch_uri, :query => query_options)
        return results[:parsed]
        #articles += results["PubmedArticleSet"]["PubmedArticle"]
        query_options[:retstart] += query_options[:retmax]
      end
      articles
    end
    
    def extract_articles(doc)
      articles = []
      doc.xpath('PubmedArticleSet/PubmedArticle').each do |article|
        a = {}
        
        articles << a
      end
    end
    
  end
end
