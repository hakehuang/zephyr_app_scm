#!/bin/ruby

=begin
create board generator for all give platforms
=end

require 'fileutils'
require 'tenjin'

require_relative 'platform_config'


generator = %{ 
require 'yml_merger'
require 'pathname'
require_relative 'create_pipefile'
require_relative 'create_report'

require_relative 'zephyr_filter'

board = File.basename(__FILE__, ".rb")
@entry_yml = "#\{board\}.yml"
@search_path  = (Pathname.new(File.dirname(__FILE__)).realpath + '../records_new/').to_s
merge_unit      = YML_Merger.new(
    @entry_yml, @search_path
    )
merged_data     = merge_unit.process()
puts "creating './merged_data.yml'"
File.write('./merged_data.yml', YAML.dump(merged_data))
board_name = ZEPHER_FILTER::get_board_name(board)
board_info = load_board_data(@search_path,board_name,merged_data)
create_pipefile_from_config(config: merged_data, board_name: board_name, board_info: board_info)
create_report_from_config(config: merged_data, board_name: board_name, board_info: board_info)
}


platforms.each do |plat, v|
    v.each do |surfix|
        filename = ""
        if surfix == ""
            filename = File.join(plat + ".rb")
        else
            filename = File.join(plat + "_" + surfix + ".rb")
        end
        if File.exist?(filename)
            FileUtils.rm_r filename
        end
        File.open(filename,"w") do |file|
            file.write generator
        end
    end
end


pipe_data = {}
engine = Tenjin::Engine.new()
platforms.each do |plat, v|
    v.each do |surfix|
        filename = ""
        template_name = ""
        if surfix == ""
            filename = File.join("..","records_new", plat + ".yml")
            template_name = File.join("..","template", "board_template.yml")
        else
            filename = File.join("..","records_new",plat + "_" + surfix + ".yml")
            template_name = File.join("..","template", "board_" + surfix + "_template.yml")
        end
        if File.exist?(filename)
            FileUtils.rm_r filename
        end
        pipe_data[:board] = plat
        out_line = ''
        output = engine.render(template_name, pipe_data)
        output.each_line do |line|
            out_line += line.rstrip() + "\n"
        end
        File.open(filename, 'w') {|f| f.write(out_line) }  
    end
end

  
  





