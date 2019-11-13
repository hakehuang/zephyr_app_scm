generator module yml files

#updatre the path to zephyr source code

ruby ./scan_zephyr.rb

copy records_temp/modules to records_new/


#create all platform rb and root yml file

ruby ./create_all_paltform.rb

the result will be in local folders platform.rb according to the platform_config.rb
and records_new/platform.yml accordingly

