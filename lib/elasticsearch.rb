
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
      p "Initation ElasticSearch formatter"
      @job = ENV['JOB']
      @build = ENV['BUILD']
      @es = Elasticsearch::Client.new hosts: ['http://192.168.2.47:9200'], reload_connections: true

    end

    def before_feature(feature)
      @feature = feature.title
    end

    def scenario_name(keyword, name, file_colon_line, source_indent)
      puts "#{name}"

         @scenario =  name
    end

    def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line)
      if @in_background == true
        # do nothing. background gets reported as step anyway
      else
         step_name = step_match.format_args(lambda{|param| "*#{param}*"})

        @es.index index: 'cucumber-plugin',
         type:  'step',
         body: {
          job:@job,
          build:@build,
          feature:@feature,
          scenario:@scenario,
          keyword: keyword,
          step_name: step_name,
          status:status,
          exception:exception,
          timestamp:Time.now.to_i
         }
      end
    end

end
