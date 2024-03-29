#!/bin/ruby

=begin
create board generator for all give platforms
=end

require 'fileutils'
require 'tenjin'

require_relative 'platform_config'

output_base = Pathname.new(File.dirname(__FILE__)).realpath + "../../"

=begin
update the relase version here
=end
generator = %{ 
require 'yml_merger'
require 'pathname'
require_relative 'create_pipefile'
require_relative 'create_pipefile_v2'
require_relative 'create_report'
require_relative 'zephyr_utils'

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
create_pipefile_from_config_v2(config: merged_data, board_name: board_name, template: "../template/Jenkinsfile_template_v2",
                                output_path: "../pipe_file_v2/",  board_info: board_info)
#create_report_from_config(config: merged_data, board_name: board_name, board_info: board_info, release: 'v2.4.0')
}

generator_build_only = %{ 
require 'yml_merger'
require 'pathname'
require_relative 'create_pipefile'
require_relative 'create_report'
require_relative 'zephyr_utils'

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
create_pipefile_from_config(config: merged_data, board_name: board_name, template: "../template/Jenkinsfile_build_only_template",
        output_path: "../pipe_file_v2/", board_info: board_info)
#create_report_from_config(config: merged_data, board_name: board_name, board_info: board_info, release: 'v2.4.0')
}


platforms.each do |plat, v|
    v.each do |surfix|
        filename = ""
        if surfix == ""
            filename = File.join(output_base, plat + ".rb")
        else
            filename = File.join(output_base, plat + "_" + surfix + ".rb")
        end
        if File.exist?(filename)
            FileUtils.rm_r filename
        end
        if plat == "frdm_k22f"
            File.open(filename,"w") do |file|
                file.write generator_build_only
            end
        else
            File.open(filename,"w") do |file|
                file.write generator
            end            
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
            filename = File.join(output_base, "records_new", plat + ".yml")
            template_name = File.join(output_base, "template", "board_template.yml")
        else
            filename = File.join(output_base, "records_new",plat + "_" + surfix + ".yml")
            template_name = File.join(output_base, "template", "board_" + surfix + "_template.yml")
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
