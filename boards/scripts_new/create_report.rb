require 'rubygems'
require 'nokogiri'
require 'find'
require 'fileutils'
require 'json'
require "awesome_print"
require 'yaml'
require 'tempfile'
require 'pathname'
require 'tenjin'
require 'optparse'
require 'ostruct'

require_relative 'zephyr_filter'

class Parser
  def self.parse(options)
    @args = OpenStruct.new
    @args.total_cases = 100
    @args.error_cases = 0
    @args.failure_cases = 0
    @args.skipped_cases = 0
    @args.catalog = "demo"

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: create_report.rb [options]"

      opts.on("-ttotal_cases", "--total_cases=total_cases", "total_cases") do |n|
          @args.total_cases = n
      end


      opts.on("-eerror_cases", "--error_cases=error_cases", "error_cases") do |n|
        @args.error_cases = n
      end

      opts.on("-ffailure_cases", "--failure_cases=failure_cases", "failure_cases") do |n|
        @args.failure_cases = n
      end

      opts.on("-sskipped_cases", "--skipped_cases=skipped_cases", "skipped_cases") do |n|
        @args.skipped_cases = n
      end

      opts.on("-ccatalog", "--catalog=catalog", "catalog") do |n|
        @args.catalog = n
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(options)
    return @args.to_h
  end
end

def create_report_from_commandline(data)
  @command_lines = Marshal.load(Marshal.dump(Parser.parse(data)))
  ap @command_lines
  engine = Tenjin::Engine.new()
  @content = File::read(@command_lines[:config_file].gsub("\\","/"))
  @content = YAML::load(@content)
  pipe_data = {
    :total_cases => @command_lines[:total_cases],
    :error_cases => @command_lines[:error_cases],
    :failure_cases => @command_lines[:failure_cases],
    :skipped_cases => @command_lines[:skipped_cases],
    :catalog => {}
  }
  @content["cases"].keys().each do |key|
    next if key == "attribute"
    catelog = @content["cases"][key]['catelog']
    pipe_data[:catalog][catelog] = {'cases' => []} if pipe_data[:catalog][catelog].nil?
    if @content["cases"][key].has_key?("config")
      pipe_data[:catalog][catelog]['cases'].insert(-1, 
        [key, @content["cases"][key]['path'], @content["cases"][key]['config']])
    else
      pipe_data[:catalog][catelog]['cases'].insert(-1, [key, @content["cases"][key]['path']])
    end
  end 
  output = engine.render(@command_lines[:template], pipe_data)
  File.open( "Jenkinsfile_" + @command_lines[:board_name], 'w') {|f| f.write(YAML.dump(output)) }
end


def create_report_from_config(config: "", board_name: "frdm_k64f", output_path: "../report/", 
  release: "v2.1.0-rc1", template: "../template/junit_template", data_file: "../cases_lib/data.yml", board_info: nil)
  engine = Tenjin::Engine.new()
  @content = config
  pipe_data = {
    :build_script  => @content["settings"]["build_script"],
    :run_script    => @content["settings"]["run_script"],
    :board         => board_name,
    :catalog       => {}
  }

  data = YAML.load_file(data_file)

  @content["cases"].keys().each do |key|
    key_words = ["mode", "attribute"]
    next if key_words.include?(key)
    next if @content["cases"][key].nil?
    next if ! @content["cases"][key].has_key?('path')
    next if board_info and ! ZEPHER_FILTER::case_validate(@content["cases"][key], board_info)
    catelog = @content["cases"][key]['catelog']

    if pipe_data[:catalog][catelog].nil?
      pipe_data[:catalog][catelog]                  = {'cases' => []}
      pipe_data[:catalog][catelog]['total_cases']   = 0
      pipe_data[:catalog][catelog]['error_cases']   = 0
      pipe_data[:catalog][catelog]['failure_cases'] = 0
      pipe_data[:catalog][catelog]['skipped_cases'] = 0
      pipe_data[:catalog][catelog]['catalog']       = catelog
    end
    matched = false
    matched_hash = {}
    data.keys.each do |case_name|
      next if matched_hash.has_key?(case_name)
      if ZEPHER_FILTER::is_case_include?(case_name, key)
        matched = true
        if @content["cases"][key]['result'].nil?
          matched_hash[case_name] = 1
          section_name = data[case_name]
          if ! @content["cases"][key]['build_only'].nil?
            pipe_data[:catalog][catelog]['skipped_cases'] += 1
            pipe_data[:catalog][catelog]['cases'].insert(-1, {'case_name':case_name, 'section_name':"#{board_name}:#{section_name}", 'result':'SKIP'})
          else
            pipe_data[:catalog][catelog]['cases'].insert(-1, {'case_name':case_name, 'section_name':"#{board_name}:#{section_name}", 'result':'PASS'})
            pipe_data[:catalog][catelog]['total_cases'] += 1
          end
        else
          result = @content["cases"][key]['result'].strip.upcase
          if result == 'SKIP'
            pipe_data[:catalog][catelog]['skipped_cases'] += 1
            puts "skip case #{case_name}"
          elsif result == 'FAILURE'
            pipe_data[:catalog][catelog]['failure_cases'] += 1
          else
            pipe_data[:catalog][catelog]['error_cases'] += 1
          end
          matched_hash[case_name] = 1
          section_name = data[case_name]
          pipe_data[:catalog][catelog]['total_cases'] += 1
          pipe_data[:catalog][catelog]['cases'].insert(-1, {'case_name':case_name, 'section_name':"#{board_name}:#{section_name}", 'result':result})
        end
      end
    end
    if ! matched
      puts "no matched found for #{key}"
    end
  end
  output = engine.render(template, pipe_data)
  FileUtils::mkdir_p output_path
  board_pipe_name = @content["settings"]["case_pipe_name"]
  File.open( output_path + "report_" + board_pipe_name + "_" + release.split(" ").join('_')+ ".xml", 'w') {|f| f.write(Nokogiri::XML(output).to_xml)}
end

#create_pipefile_from_config(ARGV)
