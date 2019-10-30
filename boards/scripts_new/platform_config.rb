
def platforms()
    platforms_config = {
    "frdm_kl25z" => ["", "drivers", "kernel"],
    "frdm_k64f" => ["", "drivers", "samples", "samples2", "kernel", "usb"],
    "frdm_k22f" => ["", "drivers", "samples", "samples2", "kernel"],
    "frdm_k82f" => ["", "drivers", "samples", "samples2", "kernel"],
    "frdm_kw41z" => ["", "drivers", "samples", "kernel"],
    "lpcxpresso54114_m0" => ["", "drivers", "samples",  "kernel"],
    "lpcxpresso54114_m4" => ["", "drivers", "samples",  "kernel"],

    "mimxrt1015_evk" => ["", "drivers", "samples", "samples2", "kernel"],
    "mimxrt1020_evk" => ["", "drivers", "samples", "samples2", "kernel"],
    "mimxrt1050_evk" => ["", "drivers", "samples", "samples2", "kernel"],
    "mimxrt1060_evk" => ["", "drivers", "samples", "samples2", "kernel"],
    "mimxrt1064_evk" => ["", "drivers", "samples", "samples2", "kernel"],

    "twr_ke18f" => ["", "drivers", "samples", "kernel"],
    "twr_kv58f220m" => ["", "drivers", "samples", "kernel"],
    }
    return platforms_config
end
