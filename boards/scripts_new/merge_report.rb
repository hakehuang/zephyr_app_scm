require 'logger'
require 'nokogiri'
require 'fileutils'

require_relative 'platform_config'

$log = Logger.new(STDOUT)
$log.level = Logger::WARN

def xml_load(file_path)
	doc = File.open(file_path) { |f| Nokogiri::XML(f) }
	return doc
end


def merge_by_compare(xml_data, platform_reports)
	if platform_reports.nil?
		platform_reports = Nokogiri::XML(Nokogiri::XML::Builder.new.to_xml)
		xml_data.xpath("//testsuites").each do |node|
			platform_reports.add_child(node)
		end
	else
		fnode = platform_reports.xpath("//testsuites")[0]
		xml_data.xpath("//testsuite").each do |node|
			fnode.add_child(node)
		end
	end
	return platform_reports
end


if __FILE__ == $0
	tag = "v2.1.0-rc1"
	$log.level = Logger::INFO
	if ! File.exist?("../report/all/")
		FileUtils.mkdir "../report/all/"
	end
	platforms.each do |plat, v|
		platform_reports = nil
	    v.each do |surfix|
	        filename = ""
	        if surfix == ""
	            filename = File.join("report_" + plat + "_#{tag}.xml")
	        else
	            filename = File.join("report_" + plat + "_" + surfix + "_#{tag}.xml")
	        end
	        file_path = File.join( "../report", filename)
	        if File.exist?(file_path)
	        	puts file_path
	        	xml_data = xml_load(file_path)
	        	platform_reports = merge_by_compare(xml_data, platform_reports)
	        end
	    end
	    out_file = File.join("../report", "all", "report_" + plat + "_all" + "_#{tag}.xml")
	    File.open(out_file, 'w') do |file|
    		file << platform_reports.to_xml
		end
	end

end