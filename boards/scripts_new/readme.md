generator module yml files

#updatre the path to zephyr source code

ruby ./scan_zephyr.rb

copy records_temp/modules to records_new/


# urgly need generate the hello_world .config for each platform
  and put .config to records_new/boards/arm/<platform>/

## specially for lpcxpresso54114_m0 and m4 need rename to board.config


#create all platform rb and root yml file

ruby ./create_all_paltform.rb

the result will be in local folders platform.rb according to the platform_config.rb
and records_new/platform.yml accordingly

