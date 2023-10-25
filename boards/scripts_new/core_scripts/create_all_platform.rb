#!/bin/ruby

=begin
create board generator for all give platforms
=end

require 'fileutils'
require 'tenjin'

require_relative 'platform_config'

output_base = Pathname.new(File.dirname(__FILE__)).realpath + "../"
boards_base = Pathname.new(File.dirname(__FILE__)).realpath + "../../"

=begin
update the relase version here
=end
generator = %{ 
require 'yml_merger'
require 'pathname'
require_relative 'core_scripts/create_pipefile_west'
require_relative 'core_scripts/create_report'
require_relative 'core_scripts/zephyr_utils'

require_relative 'core_scripts/zephyr_filter'

board = File.basename(__FILE__, ".rb")
@entry_yml = "#\{board\}.yml"
@search_path  = (Pathname.new(File.dirname(__FILE__)).realpath + '../records_new/').to_s
merge_unit      = YML_Merger.new(
    @entry_yml, @search_path
    )
merged_data     = merge_unit.process()
puts "creating './merged_data.yml'"
#File.write('./merged_data.yml', YAML.dump(merged_data))
board_name = ZEPHER_FILTER::get_board_name(board)
board_info = load_board_data(@search_path,board_name,merged_data)
#File.write('./board_info.yml', YAML.dump(board_info))
create_pipefile_from_config(config: merged_data, board_name: board_name, board_info: board_info)
#create_report_from_config(config: merged_data, board_name: board_name, board_info: board_info, release: 'v2.4.0')
}

generator_build_only = %{ 
require 'yml_merger'
require 'pathname'
require_relative 'core_scripts/create_pipefile_west'
require_relative 'core_scripts/create_report'
require_relative 'core_scripts/zephyr_utils'

require_relative 'core_scripts/zephyr_filter'

board = File.basename(__FILE__, ".rb")
@entry_yml = "#\{board\}.yml"
@search_path  = (Pathname.new(File.dirname(__FILE__)).realpath + '../records_new/').to_s
merge_unit      = YML_Merger.new(
    @entry_yml, @search_path
    )
merged_data     = merge_unit.process()
puts "creating './merged_data.yml'"
#File.write('./merged_data.yml', YAML.dump(merged_data))
board_name = ZEPHER_FILTER::get_board_name(board)
board_info = load_board_data(@search_path,board_name,merged_data)
create_pipefile_from_config(config: merged_data, board_name: board_name, template: "../../template/Jenkinsfile_build_only_template", board_info: board_info)
#create_report_from_config(config: merged_data, board_name: board_name, board_info: board_info, release: 'v2.4.0')
}

generator_derived = %{ 
require 'yml_merger'
require 'pathname'
require_relative 'core_scripts/create_pipefile_west'
require_relative 'core_scripts/create_report'
require_relative 'core_scripts/zephyr_utils'

require_relative 'core_scripts/zephyr_filter'

board = File.basename(__FILE__, ".rb")
@entry_yml = "#\{board\}.yml"
@search_path  = (Pathname.new(File.dirname(__FILE__)).realpath + '../records_new/').to_s
merge_unit      = YML_Merger.new(
    @entry_yml, @search_path
    )
merged_data     = merge_unit.process()
puts "creating './merged_data.yml'"
#File.write('./merged_data.yml', YAML.dump(merged_data))
board_name = ZEPHER_FILTER::get_derived_board_name(board, "${@drv}")
board_info = load_board_data(@search_path,board_name,merged_data)
#File.write('./board_info.yml', YAML.dump(board_info))
create_pipefile_from_config(config: merged_data, board_name: board_name, board_info: board_info)
#create_report_from_config(config: merged_data, board_name: board_name, board_info: board_info, release: 'v2.4.0')
}

generator_build_only_derived = %{ 
require 'yml_merger'
require 'pathname'
require_relative 'core_scripts/create_pipefile_west'
require_relative 'core_scripts/create_report'
require_relative 'core_scripts/zephyr_utils'

require_relative 'core_scripts/zephyr_filter'

board = File.basename(__FILE__, ".rb")
@entry_yml = "#\{board\}.yml"
@search_path  = (Pathname.new(File.dirname(__FILE__)).realpath + '../records_new/').to_s
merge_unit      = YML_Merger.new(
    @entry_yml, @search_path
    )
merged_data     = merge_unit.process()
puts "creating './merged_data.yml'"
#File.write('./merged_data.yml', YAML.dump(merged_data))
board_name = ZEPHER_FILTER::get_derived_board_name(board, "${@drv}")
board_info = load_board_data(@search_path,board_name,merged_data)
create_pipefile_from_config(config: merged_data, board_name: board_name, template: "../../template/Jenkinsfile_build_only_template", board_info: board_info)
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
        if ["frdm_k22f", "mimxrt1064_evk"].include? plat
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
            filename = File.join(boards_base, "records_new", plat + ".yml")
            template_name = File.join(boards_base,"template", "board_template.yml")
        else
            filename = File.join(boards_base, "records_new",plat + "_" + surfix + ".yml")
            template_name = File.join(boards_base, "template", "board_" + surfix + "_template.yml")
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

drv_data = {}
platforms_drived.each do |plat, drvs|
    drvs.each do |drv ,v|
        v.each do |surfix|
            filename = ""
            if surfix == ""
                filename = File.join(output_base, plat + "_#{drv}.rb")
            else
                filename = File.join(output_base, plat + "_#{drv}_" + surfix + ".rb")
            end
            if File.exist?(filename)
                FileUtils.rm_r filename
            end
            drv_data[:drv] = drv

            if ["frdm_k22f", "mimxrt1064_evk"].include? plat
                File.open(filename,"w") do |file|
                    t = Tenjin::SafeTemplate.new(:input=>generator_build_only_derived)
                    output = t.render(drv_data)
                    file.write output
                end
            else
                File.open(filename,"w") do |file|
                    t = Tenjin::SafeTemplate.new(:input=>generator_derived)
                    output = t.render(drv_data)
                    file.write output
                end
            end
        end
    end
end

pipe_data = {}
engine = Tenjin::Engine.new()
platforms_drived.each do |plat, drvs|
    drvs.each do |drv ,v|
        v.each do |surfix|
            filename = ""
            template_name = ""
            if surfix == ""
                filename = File.join(boards_base,"records_new", plat + "_#{drv}.yml")
                template_name = File.join(boards_base,"template", "board_template.yml")
            else
                filename = File.join(boards_base, "records_new",plat + "_#{drv}_#{surfix}" + ".yml")
                template_name = File.join(boards_base,"template", "board_" + surfix + "_template.yml")
            end
            if File.exist?(filename)
                FileUtils.rm_r filename
            end
            pipe_data[:board] = plat + "_#{drv}"
            out_line = ''
            output = engine.render(template_name, pipe_data)
            output.each_line do |line|
                out_line += line.rstrip() + "\n"
            end
            File.open(filename, 'w') {|f| f.write(out_line) }
        end
    end
end
