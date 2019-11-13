
require 'rubygems'
require 'fileutils'
require "logger"

require_relative 'platform_config'


$log = Logger.new(STDOUT)
$log.level = Logger::WARN

platforms.each do |plat, v|
    v.each do |surfix|
        if surfix == ""
            filename = File.join(plat + ".rb")
        else
            filename = File.join(plat + "_" + surfix + ".rb")
        end
        puts Dir.pwd
        puts filename
        ret = system("ruby #{filename}")
        if ! ret
            $log.warn("#{filename} pare error #{ret}")
        end
    end
end

