generator module yml files

#update the path to zephyr source code

ruby ./scan_zephyr.rb

copy records_temp/modules to records_new/
copy records_temp/boards_.yml to template/

update the template by diff the changes


# urgly need generate the hello_world .config for each platform
  and put .config to records_new/boards/arm/<platform>/

## specially for lpcxpresso54114_m0 and m4 need rename to board.config

## create dts plain text from dts.tmp e.g.
```
	dtc -O dtb -o mimxrt1010_evk.dtb mimxrt1010_evk.dts.pre.tmp
	dtc -I dtb -O dts mimxrt1010_evk.dtb > mimxrt1010_evk.dts_compiled
```


#create all platform rb and root yml file

ruby ./create_all_platform.rb

the result will be in local folders platform.rb according to the platform_config.rb
and records_new/platform.yml accordingly


#create all platform pipe files
ruby ./run_all.rb

# run platform_config.rb to get all failure cases
ruby ./platform_config.rb


# when add new boards dividor

update three files platform_config.rb, scan_zephyr.rb, zephyr_filter.rb, zephyr_utils.rb

