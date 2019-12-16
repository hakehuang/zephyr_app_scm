require 'rest-client'
require 'logger'
require 'json'
require 'nokogiri'


$logger = Logger.new(STDOUT)
$logger.level = Logger::WARN
$site = "http://92.120.145.179:8080"

def platforms()
    platforms_config = {
    "frdm_kl25z" => ["", "2", "drivers", "samples", "kernel", "kernel2"],
    "frdm_k64f" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2", "usb"],
    "frdm_k32l2b3" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2", "usb"],
#    "frdm_k22f" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2"],
#    "frdm_kl46z" => ["", "2", "drivers", "kernel", "kernel2"],
    "frdm_k82f" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2"],
    "frdm_kw41z" => ["", "2", "drivers", "samples", "kernel", "kernel2"],
    "lpcxpresso54114_m0" => ["", "2", "drivers", "samples",  "kernel", "kernel2"],
    "lpcxpresso54114_m4" => ["", "2", "drivers", "samples",  "kernel", "kernel2"],

    "mimxrt1015_evk" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2"],
    "mimxrt1020_evk" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2"],
    "mimxrt1050_evk" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2"],
    "mimxrt1060_evk" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2"],
    "mimxrt1064_evk" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2"],

    "twr_ke18f" => ["", "2", "drivers", "samples", "kernel", "kernel2"],
    "twr_kv58f220m" => ["", "2", "drivers", "samples", "kernel", "kernel2"],
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
    if get_build_status(build_url) == "SUCCESS"
        url  = URI::join(build_url, 'consoleFull').to_s
        fulllog = RestClient::Request.execute method: :get, url: url, user: 'zephyr', password: 'zephyr'
        html_log = CGI.unescapeHTML(fulllog.to_s)
        results = html_log.match(/<testsuites((?!<\/testsuites>).|\n)+<\/testsuites>/m)
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

def get_no_pass_cases_by_plat(plat)
  jobs_hash = get_jobs()
  ret = {}
  jobs_hash.each do |v|
    vname = v['name']
    if ! jobs_in_platfrom(vname)
        puts "missing for #{vname}!!!!!!!"
    else
        puts v['url']
        build_hash = get_latest_build(v['url'])
        log = get_build_full_log(build_hash['url'])
        log.to_a.each do |ll|
            pll = parser_log(ll)
            if pll and pll["result"] != "pass"
                ret.merge!(pll)
            end
        end
    end
  end
  return ret
end

if __FILE__ == $0
  #$logger.level = Logger::INFO
  jobs_hash = get_jobs()


  #puts jobs_in_platfrom("frdm_kl25_kernel2")

  build_hash = get_latest_build("http://92.120.145.179:8080/job/failure_cases")
  
  log = get_build_full_log(build_hash['url'])
  log.to_a.each do |ll|
    puts parser_log(ll)
  end
#=begin
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

  get_no_pass_cases_by_plat("frdm_k64f")
#=end

 return 0
end
