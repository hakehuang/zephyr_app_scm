require 'nokogiri'
require 'logger'

require_relative 'platform_config'

$log = Logger.new(STDOUT)
$log.level = Logger::WARN

def xml_hash(file_path)

	dom = Nokogiri::XML(File.read(file_path))
	hash = dom.root.element_children.each_with_object(Hash.new) do |e, h|
  		h[e.name.to_sym] = e.content
	end

	$log.info hash.inspect
end


def merge_by_compare(hash_data, platform_reports_hash)
	if platform_reports_hash.size == 0
		platform_reports_hash.merge!(hash_data)
		return
	end
	

end


if __FILE__ == $0

	$log.level = Logger::INFO
	platforms.each do |plat, v|
		platform_reports_hash = {}
	    v.each do |surfix|
	        filename = ""
	        if surfix == ""
	            filename = File.join(plat + ".rb")
	        else
	            filename = File.join(plat + "_" + surfix + ".rb")
	        end
	        hash_data = xml_hash(filename) if File.exist?(filename)
	        merge_by_compare(hash_data, platform_reports_hash)
	    end
	end

end