
require 'rubygems'
require 'fileutils'
require "logger"

require_relative 'platform_config'


$log = Logger.new(STDOUT)
$log.level = Logger::WARN

threads_list = Array.new
platforms.each do |plat, v|
    v.each do |surfix|
        if surfix == ""
            filename = File.join(plat + ".rb")
        else
            filename = File.join(plat + "_" + surfix + ".rb")
        end
        puts Dir.pwd
        puts filename
        t = Thread.new {
            ret = system("ruby #{filename}")
            if ! ret
                $log.warn("#{filename} pare error #{ret}")
            end
        }
        threads_list.append(t)
    end
    threads_list.each {|t| t.join}
    puts plat, " processing end"
end
puts "all processing end"

