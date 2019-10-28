#!/bin/ruby

require 'fileutils'

platforms = {
    "frdm_kl25z" => ["", "drivers", "samples", "kernel"],
    "frdm_k64f" => ["", "drivers", "samples", "kernel"],
    "frdm_k22f" => ["", "drivers", "samples", "kernel"],
    "frdm_k82f" => ["", "drivers", "samples", "kernel"],
    "frdm_kw41z" => ["", "drivers", "samples", "kernel"],
    "lpcxpresso54114_m0" => ["", "drivers", "samples", "kernel"],
    "lpcxpresso54114_m4" => ["", "drivers", "samples", "kernel"],

    "mimxrt1015_evk" => ["", "drivers", "samples", "kernel"],
    "mimxrt1020_evk" => ["", "drivers", "samples", "kernel"],
    "mimxrt1050_evk" => ["", "drivers", "samples", "kernel"],
    "mimxrt1060_evk" => ["", "drivers", "samples", "kernel"],
    "mimxrt1064_evk" => ["", "drivers", "samples", "kernel"],

    "twr_ke18f" => ["", "drivers", "samples", "kernel"],
    "twr_kv58f220m" => ["", "drivers", "samples", "kernel"],
}

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
board_info = load_board_data(@search_path,board_name)
create_pipefile_from_config(config: merged_data, board_name: board_name, board_info: board_info)
create_report_from_config(config: merged_data, board_name: board_name, board_info: board_info)
}


platforms.each do |plat, v|
    v.each do |surfix|
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

