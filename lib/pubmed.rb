#!/usr/bin/env ruby
require 'httparty'
require 'nokogiri'

module PubMed
  class Entrez
    
    include HTTParty
    base_uri 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/'

    class Parser::NokogiriXML < HTTParty::Parser
      def parse
        Nokogiri.parse(body)
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
    
    def search(query, autofetch=false, options={})
      query_options = {
        :db => 'pubmed',
        :retmode => 'xml',
        :usehistory => 'y',
        :email => @email_address,
        :term => query
      }.update(options)
      doc = self.class.get(@search_uri, :query => query_options)
      results = {
        :total_found => doc.xpath("eSearchResult/Count").text,
        :query_key => doc.xpath("eSearchResult/QueryKey").text,
        :web_env => doc.xpath("eSearchResult/WebEnv").text,        
      }
      if autofetch
        total = options.has_key?(:retmax) ? options[:retmax] : results[:total_found]
        results[:articles] = fetch_search_results(
          results[:web_env], 
          results[:query_key], 
          total.to_i
        )
      else
        results[:pmids] = doc.xpath('eSearchResult/IdList/Id').collect(&:text)
        results[:raw] = doc.to_s
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
        doc = self.class.get(@fetch_uri, :query => query_options)
        articles += extract_articles(doc)
        query_options[:retstart] += query_options[:retmax]
      end
      articles
    end
    
    def extract_articles(doc)
      extracted_articles = []
      doc.xpath('PubmedArticleSet/PubmedArticle').each do |article|
        a = {:raw => article.to_s}
        
        a[:pmid] = article.xpath('MedlineCitation/PMID').text
        a[:title] = article.xpath('MedlineCitation/Article/ArticleTitle').text
        a[:authors] = []
        article.xpath('MedlineCitation/Article/AuthorList/Author[@ValidYN="Y"]').each do |auth|
          if auth.xpath('LastName')
            last_name = auth.xpath('LastName').text
            first_name = auth.xpath('Initials') ? auth.xpath('Initials').text : auth.xpath('ForeName').text
            a[:authors] << "#{last_name} #{first_name}"
          end
        end
        
        a[:affiliation] = article.xpath('MedlineCitation/Article/Affiliation').text
        a[:abstract] = article.xpath('MedlineCitation/Article/Abstract/AbstractText').text
        a[:abstract_copyright] = article.xpath('MedlineCitation/Article/Abstract/CopyrightInformation').text
        a[:pubmed_status] = article.xpath('PubmedData/PublicationStatus').text
        a[:medline_status] = article.xpath('MedlineCitation').attribute('Status').text
        
        # Journal details
        journal = {}
        journal[:name] = article.xpath('MedlineCitation/Article/Journal/Title').text
        journal[:name_abbrv] = article.xpath('MedlineCitation/MedlineJournalInfo/MedlineTA').text
        journal[:issn_online] = article.xpath('MedlineCitation/Article/Journal/ISSN[@IssnType="Electronic"]').text
        journal[:issn_print] = article.xpath('MedlineCitation/Article/Journal/ISSN[@IssnType="Print"]').text
        a[:journal] = journal
        
        # Citation
        # -- basic details
        a[:pages] = article.xpath('MedlineCitation/Article/Pagination/MedlinePgn').text
        a[:volume] = article.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').text
        a[:issue] = article.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').text
        # -- pub date
        a[:medline_date] = article.xpath('MedlineCitation/Article/Journal/JournalIssue/PubDate/MedlineDate').text
        if a[:medline_date] != ""
          a[:pubdate_year] = article.xpath('PubmedData/History/PubMedPubDate[@PubStatus="pubmed"]/Year').text
          a[:pubdate_month] = article.xpath('PubmedData/History/PubMedPubDate[@PubStatus="pubmed"]/Month').text
          a[:pubdate_day] = article.xpath('PubmedData/History/PubMedPubDate[@PubStatus="pubmed"]/Day').text
        else
          a[:pubdate_year] = article.xpath('MedlineCitation/Article/Journal/JournalIssue/PubDate/Year').text
          a[:pubdate_month] = article.xpath('MedlineCitation/Article/Journal/JournalIssue/PubDate/Month').text
          a[:pubdate_day] = article.xpath('MedlineCitation/Article/Journal/JournalIssue/PubDate/Day').text
        end
        a[:pubdate] = "#{a[:pubdate_year]} #{a[:pubdate_month]} #{a[:pubdate_day]}"
        
        # MeSH headings
        a[:subjects] = []
        article.xpath('MedlineCitation/MeshHeadingList/MeshHeading').each do |subj|
          desc = subj.xpath('DescriptorName')
          desc_name = desc.text
          desc_is_major = desc.attribute('MajorTopicYN').text == 'Y' ? true : false
          a[:subjects] << {:name => desc_name, :qualifier => "", :is_major => desc_is_major}
          
          subj.xpath('QualifierName').each do |qual|
            qual_name = qual.text
            qual_is_major = qual.attribute('MajorTopicYN').text == 'Y' ? true : false
            a[:subjects] << {:name => desc_name, :qualifier => qual_name, :is_major => qual_is_major}
          end
        end
        
        extracted_articles << a
      end
      extracted_articles
    end
    
  end
end
