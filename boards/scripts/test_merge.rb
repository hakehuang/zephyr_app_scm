require 'yml_merger'
require 'Pathname'

@entry_yml = "frdm_k64f.yml"
@search_path  = (Pathname.new(File.dirname(__FILE__)).realpath + '../records/').to_s
puts @search_path
merge_unit      = YML_Merger.new(
    @entry_yml, @search_path
    )
merged_data     = merge_unit.process()
puts "creating './merged_data.yml'"
File.write('./merged_data.yml', YAML.dump(merged_data))
