require 'rubygems'
require 'yaml'
require 'fileutils'

content = File::read(ARGV.first)
content = YAML::load(content)


if File.directory?('cases')
    FileUtils.rm_rf('cases')
end
puts "----------"
puts ARGV.first
puts content

content['cases'].each do |testcase, v|
    # puts testcase
    FileUtils.mkdir_p "cases/#{testcase}"
    File.open(File.join("cases/#{testcase}", "info.yml"),"w") do |file|
      file.puts "no_pattern: ['PROJECT EXECUTION FAILED']"
      file.puts "pattern: ['PROJECT EXECUTION SUCCESSFUL']"
      file.puts "auto: 1"
      file.puts "interact: 1"
    end
    File.open(File.join("cases/#{testcase}", "interact.py"),"w") do |file|
      file.puts "#!/usr/bin/env python"
      file.puts "# coding=utf-8"
      file.puts "import time"
      file.puts ""
      file.puts "time.sleep(10)"
    end
end