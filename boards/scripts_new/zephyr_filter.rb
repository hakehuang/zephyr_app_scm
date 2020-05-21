require_relative 'zephyr_filter_grammar'
require_relative 'case_map'

module ZEPHER_FILTER
  #validate case according board supporting
  def case_validate(case_hash, board_hash)
    #processing neg_list
    neg_list.each do |k|
        if case_hash.has_key?(k) 
            if k == "skip" and case_hash[k] == true
                return false
            end
            if k == "skip" and case_hash[k] == "true"
                return false
            end
            if k == "build_only" and ! case_hash[k]
                return false
            end
            if k == "arch_exclude" and case_hash[k].include?(board_hash["arch"])
                return false
            end
            if k == "platform_exclude" and case_hash[k].include?(board_hash["identifier"])
                return false
            end
        end
    end
    #processing pos_list
    pos_list.each do |k|
        if case_hash.has_key?(k)
            if k == "arch_whitelist" and ! case_hash[k].include?(board_hash["arch"])
                return false
            end
            if k == "platform_whitelist" and ! case_hash[k].include?(board_hash["identifier"])
                return false
            end
        end
    end
    #processing neural_list
    neural_list.each do |k|
        if case_hash.has_key?(k)
            if k == "min_ram" and board_hash.has_key?("ram") and case_hash[k].to_i > board_hash["ram"]
                return false
            end
            if k == "min_flash" and board_hash.has_key?("flash") and case_hash[k].to_i > board_hash["flash"]
                return false
            end
            if k == "depends_on"
              if board_hash.has_key?("supported")
                case_hash[k].split().each do |k|
                  if ! board_hash["supported"].include?(k)
                    match = false
                    board_hash["supported"].each do |kk|
                      if kk.include?(k)
                        match = true
                        break
                      end
                    end
                    if match == false
                      return false
                    end
                  end
                end
              else
                return false
              end
            end
            #TO do filter expression parser

            if k == "filter" and board_hash.has_key?("settings") and board_hash['settings'].has_key?("no_filter")
              return zephyr_filter_parser(case_hash[k], board_hash)
            end
            if k == "type" and case_hash[k] == "unit"
              return false
            end
        end
    end
    return true
  end
  module_function :case_validate

  def neg_list
    ["skip", "build_only", "arch_exclude", "platform_exclude"]
  end
  module_function :neg_list

  def pos_list
    ["arch_whitelist", "platform_whitelist"]
  end
  module_function :pos_list
  
  def neural_list
    ["min_ram", "min_flash", "depends_on", "filter", "type"]
  end
  module_function :neural_list

  def get_board_name(instr)
    filter_list = [/_2$/, /_3$/, /_samples$/, /_samples2$/, /_kernel$/, /_kernel2$/, /_usb$/, /_drivers$/, /_drivers$/, /_failures$/]
    temp_str = instr.dup
    filter_list.each do |f|
      temp_str.gsub!(f, '')
    end
    temp_str
  end
  module_function :get_board_name


  def is_case_include?(case_name , key)
    return true if case_name.include? key
    return true if CASE_MAP.has_key?(key) and case_name.include? CASE_MAP[key]
=begin
    if key.split('.').count > 2 and case_name.include? "kernel."
      #we need compare the former two things
      new_key = key.split('.')[0..1].join('.')
      return true if case_name.include? new_key
    end
=end
#=begin
    if case_name.include? "kernel.common"
      new_key = key.split('.')[0..1].join('.')
      new_case_name = case_name.gsub('kernel.common', 'kernel')
      return true if new_case_name.include? new_key
    end
#=end
    return false
  end
  module_function :is_case_include?
end