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

def create_pipefile_from_commandline(data)
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
    catelog = @content["cases"][key]['catelog']
    pipe_data[:catalog][catelog] = {'cases' => []} if pipe_data[:catalog][catelog].nil?
    case_array = [key, @content["cases"][key]['path']]
    options_array = []
    if @content["cases"][key].has_key?("config")
      options_array.insert(-1, "-DCONF_FILE=#{@content["cases"][key]['config']}")
    end
    if @content["cases"][key].has_key?("overlay")
      options_array.insert(-1, "-DOVERLAY_CONFIG=#{@content["cases"][key]['overlay']}")
    end
    if @content["cases"][key].has_key?("extra_configs")
      @content["cases"][key]["extra_configs"].each do |conf|
        options_array.insert(-1, "-D#{conf}")
      end
    end
    case_array.insert(-1, options_array.join(" "))
    pipe_data[:catalog][catelog]['cases'].insert(-1, case_array)
  end
  output = engine.render(@command_lines[:template], pipe_data)
  File.open( "Jenkinsfile_" + @command_lines[:board_name], 'w') {|f| f.write(YAML.dump(output)) }
end

def create_pipefile_from_config(config: "", board_name: "frdm_k64f", output_path: "../pipe_file/",
  docker_name: "confident_sinoussi", template: "../template/Jenkinsfile_template")
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
    catelog = @content["cases"][key]['catelog']
    pipe_data[:catalog][catelog] = {'cases' => []} if pipe_data[:catalog][catelog].nil?
    case_array = [key, @content["cases"][key]['path']]
    options_array = []
    if @content["cases"][key].has_key?("config")
      options_array.insert(-1, "-DCONF_FILE=#{@content["cases"][key]['config']}")
    end
    if @content["cases"][key].has_key?("overlay")
      options_array.insert(-1, "-DOVERLAY_CONFIG=#{@content["cases"][key]['overlay']}")
    end
    if @content["cases"][key].has_key?("extra_configs")
      @content["cases"][key]["extra_configs"].each do |conf|
        options_array.insert(-1, "-D#{conf}")
      end
    end
    case_array.insert(-1, options_array.join(" "))
    pipe_data[:catalog][catelog]['cases'].insert(-1, case_array)
  end
  output = engine.render(template, pipe_data)
  FileUtils::mkdir_p output_path
  board_pipe_name = @content["settings"]["case_pipe_name"]
  File.open( output_path + "Jenkinsfile_" + board_pipe_name, 'w') {|f| f.write(output) } 
end

#create_pipefile_from_config(ARGV)
