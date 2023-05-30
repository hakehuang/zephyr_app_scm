require 'rest-client'
require 'logger'
require 'json'
require 'nokogiri'
require 'awesome_print'


$logger = Logger.new(STDOUT)
$logger.level = Logger::WARN
$site = "http://92.120.145.179:8080"

=begin
class String
    def scan(m)
        results = []
        logs = self.match(m).to_a
        istring = self.match(m).string
        while not logs.nil?
            istring = istring.sub(logs[0], '')
            results.insert(-1, logs[0])
            logs = istring.match(m)
        end
        return results
    end
end
=end

def platforms()
    platforms_config = {
    "frdm_kl25z" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    "frdm_k64f" => ["", "2", "3", "4", "5", "6", "7", "cmsis", "drivers", "samples",
        "shield", "bt1", "bt2", "can", "socket", "traffic",
        "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
#    "frdm_k32l2b3" => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "usb"],
    "frdm_k22f" => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
#    "frdm_kl46z" => ["", "2", "3", "drivers", "kernel", "kernel2"],
    "frdm_k82f" => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "frdm_kw41z" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples", "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso54114_m0" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",  "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso54114_m4" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",  "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso55s69_cpu0"  => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
#   "lpcxpresso55s69_cpu1"  => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso55s69_ns"  => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso55s16" => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso55s28_ns" => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso55s28"    => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso55s36"    => ["", "2", "3", "4", "5", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    "mimxrt1010_evk" => ["", "2", "3", "4", "5", "cmsis","drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1015_evk" => ["", "2", "3", "4", "5", "cmsis","drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1020_evk" => ["", "2", "3", "4", "5", "cmsis","drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1024_evk" => ["", "2", "3", "4", "5", "cmsis","drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1050_evk" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples", "sensors", "shield", "traffic",
        "bt1", "bt2", "can", "socket", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1060_evk" => ["", "2", "3", "4", "5", "6", "7","cmsis", "drivers", "samples",  "traffic", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1040_evk" => ["", "2", "3", "4", "5", "6", "7","cmsis", "drivers", "samples",  "traffic", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1064_evk" => ["", "2", "3", "4", "5", "6", "7","cmsis", "drivers", "samples",  "traffic",
        "sensors", "shield", "bt1", "bt2", "can", "socket", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt685_evk_cm33" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt595_evk_cm33" => ["", "2", "3", "4", "5", "6", "7", "cmsis", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1170_evk_cm4" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",  "traffic",
        "sensors", "shield", "bt1", "bt2", "can", "socket", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1170_evk_cm7" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",  "traffic",
        "sensors", "shield", "bt1", "bt2", "can", "socket", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1160_evk_cm4" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",  "traffic",
        "sensors", "shield", "bt1", "bt2", "can", "socket", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "mimxrt1160_evk_cm7" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",  "traffic",
        "sensors", "shield", "bt1", "bt2", "can", "socket", "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "twr_ke18f" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples", "kernel", "kernel2", "kernel3", "kernel4"],
    "twr_kv58f220m" => ["", "2", "3", "4", "5", "6", "cmsis", "drivers", "samples", "kernel", "kernel2", "kernel3", "kernel4"],
    "mimx8mm_evk" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples", "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    "lpcxpresso55s06" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",
        "sensors", "shield", "bt1", "bt2", "can", "socket", "traffic",
        "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "rdrw610_evk" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",
        "sensors", "shield", "bt1", "bt2", "can", "socket", "traffic",
        "samples2", "kernel", "kernel2", "kernel3", "kernel4", "usb"],
    "kw45b41z_evk" => ["", "2", "3", "4", "5", "cmsis", "drivers", "samples",
        "sensors", "bt1", "bt2", "can", "socket", "traffic",
        "samples2", "kernel", "kernel2", "kernel3", "kernel4"],
    }
    return platforms_config
end


def get_jobs()
    
    url = URI::join($site, "/api/", "json?pretty=true").to_s

    jobs = RestClient::Request.execute method: :get, url: url, user: 'zephyr', password: 'zephyr'

    $logger.info JSON.parse(jobs)['jobs']

    return JSON.parse(jobs)['jobs']
end


def get_sub_jobs(jobs_url)
    url  = URI::join(jobs_url + "/", "api/", 'json?pretty=true').to_s
    jobs = RestClient::Request.execute method: :get, url: url, user: 'zephyr', password: 'zephyr'

    $logger.info JSON.parse(jobs)['jobs']

    return JSON.parse(jobs)['jobs']
end


def get_latest_build(job_url)
    sub_job_url = get_sub_jobs(job_url)[0]['url']
    
    url  = URI::join(sub_job_url, "api/", 'json?pretty=true').to_s

    jobs = RestClient::Request.execute method: :get, url: url, user: 'zephyr', password: 'zephyr'

    $logger.info JSON.parse(jobs)['builds'][0]

    return JSON.parse(jobs)['builds'][0]

end


def get_build_status(build_url)
    url  = URI::join(build_url, "api/", 'json?pretty=true').to_s

    jobs = RestClient::Request.execute method: :get, url: url, user: 'zephyr', password: 'zephyr'

    $logger.info JSON.parse(jobs)['result']

    return JSON.parse(jobs)['result']
end


def get_build_full_log(build_url)
    if get_build_status(build_url) != ""
        results = []
        url  = URI::join(build_url, 'consoleFull').to_s
        fulllog = RestClient::Request.execute method: :get, url: url, user: 'zephyr', password: 'zephyr'
        html_log = CGI.unescapeHTML(fulllog.to_s)
        #regex with no capture starting witn ?: which will return the whole group
        results = html_log.scan(/<testsuites(?:(?!<\/testsuites>).|\n)+<\/testsuites>/)
        return results
    end
end

def parser_log(result_log)
    xml_doc  = Nokogiri::XML(result_log)
    xml_doc.xpath("//testsuite").each do |node|
        ret = node.xpath("//testcase").attribute('name')
        if node.attribute('failures').to_s != "0"
            return {"name" => ret.to_s, "result" => "fail"}
        elsif node.attribute('skipped').to_s != "0"
            return {"name" => ret.to_s, "result" => "skipped"}
        end
        return {"name" => ret.to_s, "result" => "pass"}
    end
    return nil
end


def jobs_in_platfrom(vname, tplat = nil)
    platforms.each do |plat, v|
        if tplat and tplat != plat
            next
        end
        platform_reports = nil
        v.each do |surfix|
            filename = ""
            if surfix == ""
                filename = plat
            else
                filename = plat + "_" + surfix
            end
            if (vname.downcase() == filename.downcase())
                return true
            end
        end
    end
    return false
end

def get_no_pass_cases_by_plat()
  jobs_hash = get_jobs()
  ret = {}
  jobs_hash.each do |v|
    vname = v['name']
    ret[vname] = []
    if ! jobs_in_platfrom(vname)
        puts "missing for #{vname}!!!!!!!"
    else
        puts v['url']
        build_hash = get_latest_build(v['url'])
        log = get_build_full_log(build_hash['url'])
        log.to_a.each do |ll|
            pll = parser_log(ll)
            #puts pll
            if pll and pll["result"] != "pass"
                puts pll
                if ret[vname] and ! ret[vname].include?(pll)
                    ret[vname].insert(-1, pll)
                end
            end
        end
    end
  end
  puts "============"
  return ret
end

if __FILE__ == $0
  #$logger.level = Logger::INFO
  #jobs_hash = get_jobs()


  #puts jobs_in_platfrom("frdm_kl25_kernel2")
=begin
  build_hash = get_latest_build("http://92.120.145.179:8080/job/failure_cases")
  puts build_hash['url']
  log = get_build_full_log(build_hash['url'])
  puts log
=end
  #log.each do |ll|
  #  puts ll
  #  puts parser_log(ll)
  #end
=begin
  jobs_hash.each do |v|
    vname = v['name']
    if ! jobs_in_platfrom(vname)
        puts "missing for #{vname}!!!!!!!"
    else
        build_hash = get_latest_build(v['url'])
        log = get_build_full_log(build_hash['url'])
        log.to_a.each do |ll|
            puts parser_log(ll)
        end
    end
  end
=end

 ap get_no_pass_cases_by_plat()

 # return 0
end
