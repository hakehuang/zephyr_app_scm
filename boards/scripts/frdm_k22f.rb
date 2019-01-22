require 'yml_merger'
require 'Pathname'
require_relative 'create_pipefile'

board = File.basename(__FILE__, ".rb")
@entry_yml = "#{board}.yml"
@search_path  = (Pathname.new(File.dirname(__FILE__)).realpath + '../records/').to_s
merge_unit      = YML_Merger.new(
    @entry_yml, @search_path
    )
merged_data     = merge_unit.process()
#puts "creating './merged_data.yml'"
#File.write('./merged_data.yml', YAML.dump(merged_data))
create_pipefile_from_config(merged_data, board)
