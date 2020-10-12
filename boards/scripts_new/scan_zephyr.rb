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
require 'json'
require "deep_merge"

require_relative "parse_testcase"
require_relative "parse_sample"
require_relative "zephyr_filter"

LONG_CASE_DURATION = {
  'benchmark.crypto.mbedtls' => {'timeout' => 1000},
  'benchmark.kernel.scheduler' => {'timeout' => 300},
  'crypto.tinycrypt' => {'timeout' => 300},
  'crypto.tinycrypt.hmac_prng.crypto.tinycrypt.hmac_prng' => {'timeout' => 600},
  'net.iface.net.iface' => {'timeout' => 300},
  'kernel.queue' => {'timeout' => 300},
  'kernel.queue.poll' => {'timeout' => 300},
  'kernel.common.stack_protection' => {'timeout' => 300},
  'kernel.memory_protection' => {'timeout' => 300},
  'kernel.common.stack_protection_arm_fpu_sharing' => {'timeout' => 300},
  'kernel.memory_protection.userspace' => {'timeout' => 300},
  'kernel.threads.thread_stack' => {'timeout' => 300},
  'benchmark.cmsis_dsp.basicmath' => {'timeout' => 500},
  'kernel.fifo' => {'timeout' => 300},
  'kernel.fifo.poll' => {'timeout' => 300},
  'kernel.lifo' => {'timeout' => 300},
  'kernel.threads.thread_stack.kernel.threads.thread_stack' => {'timeout' => 300},
  'libraries.cmsis_dsp.basicmath' => {'timeout' => 600},
  'libraries.cmsis_dsp.statistics' => {'timeout' => 600},
  'libraries.cmsis_dsp.transform.cf64' => {'timeout' => 600},
  'libraries.cmsis_dsp.transform.cq15' => {'timeout' => 600},
  'libraries.cmsis_dsp.transform.rf32' => {'timeout' => 600},
  'libraries.cmsis_dsp.transform.cf32' => {'timeout' => 600},
  'libraries.cmsis_dsp.transform.cq31' => {'timeout' => 600},
  'libraries.cmsis_dsp.transform.rq31' => {'timeout' => 600},
  'libraries.cmsis_dsp.transform.rf64' => {'timeout' => 600},
  'libraries.cmsis_dsp.support' => {'timeout' => 600},
  'libraries.cmsis_dsp.complexmath' => {'timeout' => 600},
  'lib.heap' => {'timeout' => 500},
  'shell.core.shell.core ' => {'timeout' => 300}
}

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
      if File.file?(fn) and ( File.extname(fn) == ".yaml" or File.extname(fn) == ".dts" or fn =~ /_defconfig/) 
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
    test_case_lists = {"cases" => {}}
    testcase_hash = nil
    sample_hash = nil
    Find.find(zephyr_path) do |path|
        if File.file?(path) and File.basename(path) == "CMakeLists.txt"
            #find the testcase.yml or sample.yml in the same folder
            dir_name = File.dirname(path)
            testcase_hash = nil
            sample_hash = nil
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
                extra_args = testcase_hash['tests'][k]['extra_args']
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
                  cases['cases'][k]['extra_args'] = extra_args
                  if extra_args != testcase_hash['tests'][k]['extra_args']
                    cases['cases'][k]['extra_args'] = [testcase_hash['tests'][k]['extra_args'], extra_args].join(" ")
                  end
                end
                keep_hash = {}
                lists_to_keep(testcase_hash['tests'][k], keep_hash)
                #log.info(keep_hash)
                cases['cases'][k].merge!(keep_hash)
                if LONG_CASE_DURATION.has_key?(k)
                  # puts "**************************", k
                  test_case_lists['cases'][k] = LONG_CASE_DURATION[k]
                  # puts test_case_lists['cases'][k]
                else
                  test_case_lists['cases'][k] = ""
                end
              end

            end
            if ! sample_hash.nil?
              if sample_hash.has_key?('tests')
                sample_hash['tests'].keys.each do |k|
                  extra_args = sample_hash['tests'][k]['extra_args']
                  if sample_hash['common']
                    depends_on = sample_hash['tests'][k]['depends_on']
                    tags = sample_hash['common']['tags']
                    tags = sample_hash['tests'][k]['tags'] if sample_hash['tests'][k].has_key?('tags')
                    sample_hash['tests'][k].merge!(sample_hash['common'])
                    if ! depends_on.nil? and sample_hash['tests'][k].has_key?('depends_on') and 
                      depends_on != sample_hash['tests'][k]['depends_on']
                      #if there is depends_on in each case, merge common depends manually, as hash merged does not work
                      sample_hash['tests'][k]['depends_on'] =  sample_hash['tests'][k]['depends_on'] + " " + depends_on
                    end
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
                  if sample_hash['tests'][k].has_key?('extra_args')
                    cases['cases'][k]['extra_args'] = extra_args
                    if extra_args != sample_hash['tests'][k]['extra_args']
                      cases['cases'][k]['extra_args'] = [extra_args, sample_hash['tests'][k]['extra_args']].join(" ")
                    end
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
                  if sample_hash['common']
                    cases['cases'][kk].merge!(sample_hash['common'])
                  end
                end
              end
            end
        end
    end
    File.open(File.join(output_records_path, output_records_fname),"w") do |file|
      file.write cases.to_yaml
    end
    File.open(File.join(output_records_path, "test_cases.json"),"w") do |file|
      file.write test_case_lists.to_json
    end
end

def split_test_catalog(fn, outdir, template_dir)
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

  # comment node
  common_hash = {
    '__load__' => ['skips/${@board}.yml', 'boards/${@board}.yml'],
    'cases' => {
      "attribute" => "required",
      "__common__" => {
        "attribute" => "required"}
    }
  }

  # put catalog to template
  template_files_hash = {
    'board_template.yml' => {'settings' => {"case_pipe_name" => "${@board}"}}.deep_merge(common_hash),
    'board_2_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_2"}}.deep_merge(common_hash),
    'board_3_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_3"}}.deep_merge(common_hash),
    'board_4_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_4"}}.deep_merge(common_hash),
    'board_5_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_5"}}.deep_merge(common_hash),
    'board_cmsis_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_cmsis"}}.deep_merge(common_hash),
    'board_drivers_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_drivers"}}.deep_merge(common_hash),
    'board_kernel_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_kernel"}}.deep_merge(common_hash),
    'board_kernel2_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_kernel2"}}.deep_merge(common_hash),
    'board_samples_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_samples"}}.deep_merge(common_hash),
    'board_sensors_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_sensors"}}.deep_merge(common_hash),
    'board_shield_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_shield"}}.deep_merge(common_hash),
    'board_bt1_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_bt1"}}.deep_merge(common_hash),
    'board_bt2_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_bt2"}}.deep_merge(common_hash),
    'board_can_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_can"}}.deep_merge(common_hash),
    'board_socket_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_socket"}}.deep_merge(common_hash),
    'board_traffic_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_traffic"}}.deep_merge(common_hash),
    'board_samples2_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_samples2"}}.deep_merge(common_hash),
    'board_usb_template.yml' => {'settings' => {"case_pipe_name" => "${@board}_usb"}}.deep_merge(common_hash),
  }

  cases_cat.keys().sort!.each do |k|
    module_name = "#{k.gsub(" ", "_")}.yml"
    # puts module_name
    if module_name.downcase().start_with?("usb")
      template_files_hash['board_usb_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^cmsis_dsp/) or
      module_name.downcase().match(/^cmsis_rtos/)
      template_files_hash['board_cmsis_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().start_with?("driver")
      template_files_hash['board_drivers_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^kernel_/)
      template_files_hash['board_kernel2_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^kernel/) or
      module_name.downcase().match(/^tickless_kernel/)
      template_files_hash['board_kernel_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^sensors/)
      template_files_hash['board_sensors_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^shield/)
      template_files_hash['board_shield_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().start_with?("bluetooth_")
      template_files_hash['board_bt1_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().start_with?("bluetooth")
      template_files_hash['board_bt2_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().start_with?("can_")
      template_files_hash['board_can_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().start_with?(/^net_s/)
      template_files_hash['board_socket_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().start_with?(/^net_traffic_/)
      template_files_hash['board_traffic_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^net_[n-z]/)
      template_files_hash['board_samples2_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^net_[a-m]/) or
      module_name.downcase().match(/^net/) or
      module_name.downcase().match(/^tcp/)
      template_files_hash['board_samples_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^[a-c]/)
      template_files_hash['board_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^d/)
      template_files_hash['board_2_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^[e-k]/)
      template_files_hash['board_3_template.yml']["__load__"].unshift("modules/#{module_name}")
    elsif module_name.downcase().match(/^[l-p]/)
      template_files_hash['board_4_template.yml']["__load__"].unshift("modules/#{module_name}")
    else
      template_files_hash['board_5_template.yml']["__load__"].unshift("modules/#{module_name}")
    end
  end

  template_files_hash.each do |k, v|
    File.open(File.join(template_dir, k),"w") do |file|
      file.write template_files_hash[k].to_yaml
    end
  end

end

scan("C:/github/zephyrproject/zephyr", "../records_temp", "test.yml")
split_test_catalog("../records_temp/test.yml", "../records_temp", template_dir="../template")
