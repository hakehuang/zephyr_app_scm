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
require 'digest'

require_relative 'zephyr_filter'

class Parser
  def self.parse(options)
    @args = OpenStruct.new
    @args.docker_name = "confident_sinoussi"
    @args.board_name = "frdm_k64f"
    @args.template = "Jenkinsfile_template"
    @args.config_file = "merged_data.yml"

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: create_pitpfile.rb [options]"

      opts.on("-ddocker_name", "--docker_name=docker_name", "docker_name") do |n|
          @args.docker_name = n
      end


      opts.on("-Bboard_name", "--board_name=board_name", "board_name") do |n|
        @args.board_name = n
      end

      opts.on("-ttemplate", "--template=template", "template") do |n|
        @args.template = n
      end

      opts.on("-cconfig_file", "--config_file=config_file", "config_file") do |n|
        @args.config_file = n
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

def load_board_data(search_base, board_name)
  board_file = File.join(search_base, "boards", "arm", board_name,"#{board_name}.yaml")
  board_settings = File.join(search_base, "boards", "#{board_name}.yml")
  if File.exist?(board_file)
    board_info =  YAML.load_file(board_file)
    board_info.merge!(YAML.load_file(board_settings))
    return board_info
  else
    puts "no such board file found #{board_name} in arm"
    exit
  end
end


def create_pipefile_from_commandline(data, board_info: nil)
  md5 = Digest::MD5.new
  @command_lines = Marshal.load(Marshal.dump(Parser.parse(data)))
  ap @command_lines
  engine = Tenjin::Engine.new()
  @content = File::read(@command_lines[:config_file].gsub("\\","/"))
  @content = YAML::load(@content)
  pipe_data = {
    :docker => @command_lines[:docker_name],
    :build_script => @content["settings"]["build_script"], 
    :run_script   => @content["settings"]["run_script"], 
    :board => @command_lines[:board_name],
    :catalog => {}
  }
  @content["cases"].keys().each do |key|
    next if key == "attribute"
    next if @content["cases"][key]['result'].upcase == "SKIP"
    next if ! @content["cases"][key].has_key?('path')
    next if board_info and ! ZEPHER_FILTER::case_validate(@content["cases"][key], board_info)
    catalog = @content["cases"][key]['catalog']
    pipe_data[:catalog][catalog] = {'cases' => {}} if pipe_data[:catalog][catalog].nil?
    case_array = [key, @content["cases"][key]['path']]
    options_array = []
    if @content["cases"][key].has_key?("config")
      options_array.insert(-1, "-DCONF_FILE=#{@content["cases"][key]['config']}")
    end
    if @content["cases"][key].has_key?("overlay")
      options_array.insert(-1, "-DOVERLAY_CONFIG=#{@content["cases"][key]['overlay']}")
    end
    if @content["cases"][key].has_key?("extra_args")
      if @content["cases"][key]['extra_args'].include?("-D")
        options_array.insert(-1, %Q[#{@content["cases"][key]['extra_args']}])
      else
        options_array.insert(-1, %Q[-D#{@content["cases"][key]['extra_args']}])
      end
    end
    if @content["cases"][key].has_key?("extra_configs")
      @content["cases"][key]["extra_configs"].each do |conf|
        options_array.insert(-1, "-D#{conf}")
      end
    end
    case_array.insert(-1, options_array.join(' ')) if options_array.length
    pipe_data[:catalog][catalog]['cases'][key] = {}
    if @content["cases"][key].has_key?("build_only") and @content["cases"][key]['build_only']
      pipe_data[:catalog][catalog]['cases'][key]['build_only'] = true
    end
    md5 << options_array.join(' ')
    pipe_data[:catalog][catalog]['cases'][key]['build_path'] = File.join(case_array[1], "build_" + md5.hexdigest[0..6])
    pipe_data[:catalog][catalog]['cases'][key]['build'] = "build_" + md5.hexdigest[0..6]

    if @content["cases"][key].has_key?("scripts")
      pipe_data[:catalog][catalog]['cases'][key]['scripts'] = @content["cases"][key]['scripts']
    end


    pipe_data[:catalog][catalog]['cases'][key]['opt'] = case_array
  end
  output = engine.render(@command_lines[:template], pipe_data)
  File.open( "Jenkinsfile_" + @command_lines[:board_name], 'w') {|f| f.write(YAML.dump(output)) }
end

def create_pipefile_from_config(config: "", board_name: "frdm_k64f", output_path: "../pipe_file/",
  docker_name: "confident_sinoussi", template: "../template/Jenkinsfile_template", board_info: nil)
  md5 = Digest::MD5.new
  engine = Tenjin::Engine.new()
  @content = config
  pipe_data = {
    :docker => docker_name,
    :build_script => @content["settings"]["build_script"], 
    :run_script   => @content["settings"]["run_script"], 
    :board => board_name,
    :catalog => {}
  }
  @content["cases"].keys().each do |key|
    key_words = ["mode", "attribute"]
    next if key_words.include?(key)
    next if @content["cases"][key].nil?
    next if @content["cases"][key].has_key?('result')
    next if ! @content["cases"][key].has_key?('path')
    next if board_info and ! ZEPHER_FILTER::case_validate(@content["cases"][key], board_info)

    catalog = @content["cases"][key]['catalog'].gsub(' ', '_')
    pipe_data[:catalog][catalog] = {'cases' => {}} if pipe_data[:catalog][catalog].nil?
    case_array = [key, @content["cases"][key]['path']]
    options_array = Array.new()
    if @content["cases"][key].has_key?("config")
      options_array.insert(-1, "-DCONF_FILE=#{@content["cases"][key]['config']}")
    end
    if @content["cases"][key].has_key?("overlay")
      options_array.insert(-1, "-DOVERLAY_CONFIG=#{@content["cases"][key]['overlay']}")
    end
    if @content["cases"][key].has_key?("extra_args")
      if @content["cases"][key]['extra_args'].include?("-D")
        options_array.insert(-1, "#{@content["cases"][key]['extra_args'].gsub('"', '')}")
      else
        options_array.insert(-1, "-D#{@content["cases"][key]['extra_args'].gsub('"', '')}")
      end
    end
    if @content["cases"][key].has_key?("extra_configs")
      @content["cases"][key]["extra_configs"].each do |conf|
        options_array.insert(-1, %Q[-D#{conf.gsub('"', '')}])
      end
    end
    case_array.insert(-1, options_array.join(' ')) if options_array.length
    pipe_data[:catalog][catalog]['cases'][key] = {}
    if @content["cases"][key].has_key?("build_only") and @content["cases"][key]['build_only']
      pipe_data[:catalog][catalog]['cases'][key]['build_only'] = true
    end
    md5 << options_array.join(' ')
    pipe_data[:catalog][catalog]['cases'][key]['build_path'] = File.join(case_array[1], "build_" + md5.hexdigest[0..6])
    pipe_data[:catalog][catalog]['cases'][key]['build'] = "build_" + md5.hexdigest[0..6]

    if @content["cases"][key].has_key?("scripts")
      pipe_data[:catalog][catalog]['cases'][key]['scripts'] = @content["cases"][key]['scripts']
    end

    pipe_data[:catalog][catalog]['cases'][key]['opt'] = case_array
  end
  output = engine.render(template, pipe_data)
  out_line = ''
  output.each_line do |line|
    out_line += line.rstrip() + "\n"
  end
  FileUtils::mkdir_p output_path
  board_pipe_name = @content["settings"]["case_pipe_name"]
  File.open( output_path + "Jenkinsfile_" + board_pipe_name, 'w') {|f| f.write(out_line) }
end

#create_pipefile_from_config(ARGV)
