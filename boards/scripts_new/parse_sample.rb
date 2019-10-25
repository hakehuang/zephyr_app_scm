require 'yaml'
require 'logger'

def parse_sample_attr(fn, log = nil)
    if log.nil?
        log = Logger.new(STDOUT)
    end
    log.info("parse %s"%fn)
    return YAML.load_file(fn)
end