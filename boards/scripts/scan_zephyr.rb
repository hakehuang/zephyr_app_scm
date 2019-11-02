require 'rubygems'
require 'nokogiri'
require 'find'
require 'fileutils'
require "awesome_print"
require 'yaml'
require 'tempfile'
require 'pathname'
require 'tenjin'
require 'optparse'
require 'ostruct'
require 'logger'

require_relative "parse_testcase"
require_relative "parse_sample"
require_relative "zephyr_filter"

class Parser
  def self.parse(options)
    @args = OpenStruct.new
    @args.zephyr_apps_path = 100
    @args.records_path = 0
    @args.records_file_name = 0

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: scan_zephyr.rb [options]"

      opts.on("-zzephyr_apps_path", "--zephyr_apps_path=zephyr_apps_path", "zephyr_apps_path") do |n|
          @args.zephyr_apps_path = n
      end

      opts.on("-rrecords_path", "--records_path=records_path", "records_path") do |n|
        @args.records_path = n
      end

      opts.on("-frecords_file_name", "--records_file_name=records_file_name", "records_file_name") do |n|
        @args.failure_cases = n
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

def lists_to_keep(in_hash, out_hash)
  #base on the knowledge from https://docs.zephyrproject.org/latest/guides/test/sanitycheck.html
  all_list = ZEPHER_FILTER::neg_list + ZEPHER_FILTER::pos_list + ZEPHER_FILTER::neural_list
  in_hash.each do |k, v|
    if all_list.include?(k)
      out_hash[k] = v
    end
  end
end

def scan(zephyr_path, output_records_path, output_records_fname)
    log = Logger.new(STDOUT)

    log.info("@ zephyr_path: %s"%zephyr_path)
    log.info("@ output_records_path: %s"%output_records_path)
    log.info("@ output_records_fname: %s"%output_records_fname)

    #find the zephyr-env.cmd to identify the zephyr_base
    pa = Pathname.new(zephyr_path).to_path.split(File::SEPARATOR)
    zephyr_base = nil
    pa.each do |p|
      if zephyr_base.nil?
        zephyr_base =  p
      else
        zephyr_base =  File.join(zephyr_base, p)
      end
      if File.exist?(File.join(zephyr_base, "zephyr-env.cmd"))
        break
      end
    end
    log.info("zephyr base is %s"%zephyr_base)

    if ! File.directory?(output_records_path)
      FileUtils.mkdir_p output_records_path
      log.info("create output path %s"%output_records_path)
    else
      FileUtils.rm_r output_records_path
    end

    #move the boards yaml for arm
    Find.find(File.join(zephyr_base, "boards", "arm")) do |fn|
      if File.file?(fn) and File.extname(fn) == ".yaml"
        dir_name = File.dirname(fn)
        rel_path = Pathname.new(dir_name).relative_path_from(Pathname.new(zephyr_base))
        if ! File.exist?(File.join(output_records_path, rel_path))
          FileUtils.mkdir_p File.join(output_records_path, rel_path)
        end
        FileUtils.cp(fn,File.join(output_records_path, rel_path, File.basename(fn)))
      end
    end
    

    log.info("indentify the CMakeLists.txt")
    cases = {"cases" => {}}
    testcase_hash = nil
    sample_hash = nil
    Find.find(zephyr_path) do |path|
        if File.file?(path) and File.basename(path) == "CMakeLists.txt"
            #find the testcase.yml or sample.yml in the same folder
            dir_name = File.dirname(path)

            Find.find(dir_name) do |fn|
                if File.file?(fn) and File.basename(fn) == "testcase.yaml"
                    testcase_hash = parse_testcase_attr(fn, log)
                elsif File.file?(fn) and File.basename(fn) == "sample.yaml"
                    sample_hash = parse_sample_attr(fn, log)
                end
            end
            if ! testcase_hash.nil?
              #puts testcase_hash
              testcase_hash['tests'].keys.each do |k|
                #log.info(k)
                if testcase_hash['common']
                  tags = testcase_hash['common']['tags']
                  tags = testcase_hash['tests'][k]['tags'] if testcase_hash['tests'][k].has_key?('tags')
                  testcase_hash['tests'][k].merge!(testcase_hash['common'])
                else
                  tags = testcase_hash['tests'][k]['tags'] if testcase_hash['tests'][k].has_key?('tags')
                end
                tags = "unknown" if tags.nil?
                cases['cases'][k] = {'path' => Pathname.new(dir_name).relative_path_from(Pathname.new(zephyr_base)).to_path,
                                      'catalog' => tags
                                     }
                if testcase_hash['tests'][k].has_key?('extra_configs')
                  cases['cases'][k]['extra_configs'] = testcase_hash['tests'][k]['extra_configs']
                end
                if testcase_hash['tests'][k].has_key?('extra_args')
                  cases['cases'][k]['extra_args'] = testcase_hash['tests'][k]['extra_args']
                end
                keep_hash = {}
                lists_to_keep(testcase_hash['tests'][k], keep_hash)
                #log.info(keep_hash)
                cases['cases'][k].merge!(keep_hash)
              end

            end
            if ! sample_hash.nil?
              if sample_hash.has_key?('tests')
                sample_hash['tests'].keys.each do |k|
                
                  if sample_hash['common']
                    tags = sample_hash['common']['tags']
                    tags = sample_hash['tests'][k]['tags'] if sample_hash['tests'][k].has_key?('tags')
                    sample_hash['tests'][k].merge!(sample_hash['common'])
                  else
                    tags = sample_hash['tests'][k]['tags'] if sample_hash['tests'][k].has_key?('tags')
                  end
                  tags = "unknown" if tags.nil?
                  cases['cases'][k] = {
                    'path' => Pathname.new(dir_name).relative_path_from(Pathname.new(zephyr_base)).to_path,
                    'catalog' => tags
                  }
                  if sample_hash['tests'][k].has_key?('extra_configs')
                    cases['cases'][k]['extra_configs'] = sample_hash['tests'][k]['extra_configs']
                  end
                  keep_hash = {}
                  lists_to_keep(sample_hash['tests'][k], keep_hash)
                  #log.info(keep_hash)
                  cases['cases'][k].merge!(keep_hash)
                end
              else
                sample_hash['sample'].keys.each do |k|
                  kk = Pathname.new(dir_name).relative_path_from(Pathname.new(zephyr_base)).to_path.split(File::Separator).join(".")
                  cases['cases'][kk] = {
                    'path' => Pathname.new(dir_name).relative_path_from(Pathname.new(zephyr_base)).to_path,
                    'catalog' => sample_hash['sample']['name']
                  }
                end
              end
            end
        end
    end
    File.open(File.join(output_records_path, output_records_fname),"w") do |file|
      file.write cases.to_yaml
    end
end

def split_test_catalog(fn, outdir)
  cases = YAML.load_file(fn)
  out_put_dirs = File.join(outdir, "modules")
  FileUtils.rm_r out_put_dirs if File.exist?(out_put_dirs)
  FileUtils.mkdir_p out_put_dirs
  cases_cat = {}
  cases['cases'].each do |k, v|
    if cases_cat[v['catalog']].nil?
      cases_cat[v['catalog']] = {k => v}
    else
      cases_cat[v['catalog']].merge!({k => v})
    end
  end
  File.open(File.join(outdir, "cases_cat.yml"),"w") do |file|
      file.write cases_cat.to_yaml
  end
  cases_cat.each do |k, v|
    out_cases = {'cases' => v}
    #puts out_put_dirs, k
    File.open(File.join(out_put_dirs, "#{k.gsub(" ", "_")}.yml"),"w") do |file|
      file.write out_cases.to_yaml
    end
  end
end

scan("C:/github/zephyr", "../records_temp", "test.yml")
split_test_catalog("../records_temp/test.yml", "../records_temp")