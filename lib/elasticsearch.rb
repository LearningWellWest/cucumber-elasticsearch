
# encoding: utf-8
require 'elasticsearch'
require 'rubygems'
require 'json'
require 'ostruct'
require 'cucumber/formatter/io'
require 'gherkin/formatter/argument'
require 'base64'

class ElasticSearch

    def initialize(step_mother, io, options)
      @job = ENV['JOB']
      @build = ENV['BUILD']
      url = ENV['ES_URL'] ? ENV['ES_URL'] : ['194.218.9.53:9200']
      p "Initation ElasticSearch(#{url}) formatter for #{@job} : #{@build}"
      @es = Elasticsearch::Client.new hosts: url, reload_connections: true

    end

    def before_feature(feature)
      #p "#{feature.title}"
          
      tags = Array.new
      feature.source_tag_names.each do |tag|
        tags.push(name:tag)
      end
      @feature = FeatureTags.new(feature.title, tags)
    end

    def before_feature_element(feature_element)
      @scenario = ScenarioTags.new
      @scenario.tags  = Array.new
    end

    def tag_name(tag_name)
      #p "#{tag_name}"
      @scenario ? @scenario.tags.push(name:tag_name) : true
    end

    def scenario_name(keyword, name, file_colon_line, source_indent)
      #p "#{name}"
      @scenario.name =  name
    end

    def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line)
      if @in_background == true
        # do nothing. background gets reported as step anyway
      else
        step_name = step_match.format_args(lambda{|param| "*#{param}*"})
        #p "  #{step_name}"

        tags = Array.new
        @feature.tags.each do |tag|
          tags.push(tag)
        end
        @scenario.tags.each do |tag|
          tags.push(tag)
        end

        @es.index index: 'cucumber-plugin',
          type:  'step',
          body: {
            job:@job,
            build:@build,
            feature:@feature.name,
            scenario:@scenario.name,
            keyword: keyword,
            step_name: step_name,
            status:status,
            exception:exception,
            timestamp:Time.now.utc.iso8601,
            tags:tags
         }
      end
    end
end

class FeatureTags
  attr_accessor :name, :tags
  
  def initialize(name,tags)
    @name = name
    @tags = tags
  end
end

class ScenarioTags
  attr_accessor :name, :tags
end

