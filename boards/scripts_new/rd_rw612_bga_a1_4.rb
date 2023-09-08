 
require 'yml_merger'
require 'pathname'
require_relative 'core_scripts/create_pipefile'
require_relative 'core_scripts/create_report'
require_relative 'core_scripts/zephyr_utils'

require_relative 'core_scripts/zephyr_filter'

board = File.basename(__FILE__, ".rb")
@entry_yml = "#{board}.yml"
@search_path  = (Pathname.new(File.dirname(__FILE__)).realpath + '../records_new/').to_s
merge_unit      = YML_Merger.new(
    @entry_yml, @search_path
    )
merged_data     = merge_unit.process()
puts "creating './merged_data.yml'"
#File.write('./merged_data.yml', YAML.dump(merged_data))
board_name = ZEPHER_FILTER::get_derived_board_name(board, "a1")
board_info = load_board_data(@search_path,board_name,merged_data)
File.write('./board_info.yml', YAML.dump(board_info))
create_pipefile_from_config(config: merged_data, board_name: board_name, board_info: board_info)
#create_report_from_config(config: merged_data, board_name: board_name, board_info: board_info, release: 'v2.4.0')
