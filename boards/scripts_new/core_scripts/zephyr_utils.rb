require 'parseconfig'
require 'yaml'
require 'fileutils'
require 'pathname'
require 'os'
require 'rbdtb'


def load_board_data(search_base, board_name, board_settings)
  board = board_name.gsub('_m4', '').gsub('_m0', '')
          .gsub('_cpu0', '').gsub('_cpu1', '').gsub('_ns', '').gsub('_cm33', '')
          .gsub('_cm4', '').gsub('_cm7', '')
  board_file = File.join(search_base, "boards", "arm", board,"#{board_name}.yaml")
  board_info = {}
  if File.exist?(board_file)
    board_info =  YAML.load_file(board_file)
    board_info["settings"] = board_settings["settings"]
  else
    puts "no such board file found #{board_name} in arm #{board_file}"
    exit
  end
  config_file = File.join(search_base, "boards", "arm", board,"#{board_name}_defconfig")
  puts config_file
  if File.exist?(config_file)
    my_config = ParseConfig.new(config_file)
    board_info["configs"] = my_config.params
    more_configs = load_core_config(search_base, board_name, board)
    board_info["configs"].merge!(more_configs)
    #puts board_info["configs"]
  end
  board_dtb_file = File.join(search_base, "boards", "arm", board,"#{board_name}.dts_compiled")
  if File.exist?(board_dtb_file)
    boards_dtb = dtb_parse_file(board_dtb_file)
    board_info["dtb"] = boards_dtb
  end
  overlay_board_dtb_file = File.join(search_base, "boards", "dts", "#{board_name}.overlay")
  if File.exist?(overlay_board_dtb_file)
    overlay_board_dtb = dtb_parse_file(overlay_board_dtb_file)
    boards_dtb.deep_merge!(overlay_board_dtb)

  end
  #puts board_info
  return board_info
end


def load_core_config(search_base, board_name, board)
  config_file = File.join(search_base, "boards", "arm", board, ".config")
  config_file_board = File.join(search_base, "boards", "arm", board, "#{board_name}.config")
  my_config = nil
  puts config_file
  puts config_file_board
  if File.exist?(config_file)
    my_config = ParseConfig.new(config_file)
    #puts my_config.params
    #puts board_info["configs"]
  else
    if File.exist?(config_file_board)
      my_config = ParseConfig.new(config_file_board)
    end
  end
  return my_config.params
end

if __FILE__ == $0
  #load_core_config( "C:/github/create_pipefile/boards/records_new", "frdm_kw41z")
  puts load_board_data("C:/github/create_pipefile/boards/records_new", "twr_ke18f", Hash.new)
end