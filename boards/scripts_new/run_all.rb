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

platforms.each do |plat, v|
    v.each do |surfix|
        if surfix == ""
            filename = File.join(plat + ".rb")
        else
            filename = File.join(plat + "_" + surfix + ".rb")
        end
        puts Dir.pwd
        %x("ruby #{filename}")
    end
end

