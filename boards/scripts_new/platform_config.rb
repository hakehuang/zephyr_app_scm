
def platforms()
    platforms_config = {
    "frdm_kl25z" => ["", "2", "drivers", "kernel", "kernel2"],
    "frdm_k64f" => ["", "2", "drivers", "samples", "samples2", "kernel", "kernel2", "usb"],
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
