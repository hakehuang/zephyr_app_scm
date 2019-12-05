
def platforms()
    platforms_config = {
    "frdm_kl25z" => ["", "2", "drivers", "kernel"],
    "frdm_k64f" => ["", "2", "drivers", "samples", "samples2", "kernel", "usb"],
#    "frdm_k22f" => ["", "2", "drivers", "samples", "samples2", "kernel"],
#    "frdm_kl46z" => ["", "2", "drivers", "kernel"],
    "frdm_k82f" => ["", "2", "drivers", "samples", "samples2", "kernel"],
    "frdm_kw41z" => ["", "2", "drivers", "samples", "kernel"],
    "lpcxpresso54114_m0" => ["", "2", "drivers", "samples",  "kernel"],
    "lpcxpresso54114_m4" => ["", "2", "drivers", "samples",  "kernel"],

    "mimxrt1015_evk" => ["", "2", "drivers", "samples", "samples2", "kernel"],
    "mimxrt1020_evk" => ["", "2", "drivers", "samples", "samples2", "kernel"],
    "mimxrt1050_evk" => ["", "2", "drivers", "samples", "samples2", "kernel"],
    "mimxrt1060_evk" => ["", "2", "drivers", "samples", "samples2", "kernel"],
    "mimxrt1064_evk" => ["", "2", "drivers", "samples", "samples2", "kernel"],

    "twr_ke18f" => ["", "2", "drivers", "samples", "kernel"],
    "twr_kv58f220m" => ["", "2", "drivers", "samples", "kernel"],
    }
    return platforms_config
end
