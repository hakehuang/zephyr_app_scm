
require 'rubygems'
require 'fileutils'
require "logger"

require_relative 'platform_config'


$log = Logger.new(STDOUT)
$log.level = Logger::WARN

filter_platform = nil

if ARGV.length
    filter_platform = ARGV[0]
    puts filter_platform
end

threads_list = Array.new
platforms.each do |plat, v|
    if filter_platform and not plat.include?(filter_platform)
        next
    end
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

puts "now output derived platforms"

platforms_drived.each do |plat, drvs|
    if filter_platform and not plat.include?(filter_platform)
        next
    end
    drvs.each do |drv, v|
        v.each do |surfix|
            if surfix == ""
                filename = File.join(plat + "_#{drv}.rb")
            else
                filename = File.join(plat + "_#{drv}_" + surfix + ".rb")
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
        puts plat, " processing drv end"
    end
end
puts "all processing end"

