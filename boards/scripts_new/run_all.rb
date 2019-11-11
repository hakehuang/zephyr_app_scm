
require 'rubygems'
require 'fileutils'

require_relative 'platform_config'


platforms.each do |plat, v|
    v.each do |surfix|
        if surfix == ""
            filename = File.join(plat + ".rb")
        else
            filename = File.join(plat + "_" + surfix + ".rb")
        end
        puts Dir.pwd
        puts filename
        system("ruby #{filename}")
    end
end

