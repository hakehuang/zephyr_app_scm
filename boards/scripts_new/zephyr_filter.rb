module ZEPHER_FILTER
  #validate case according board supporting
  def case_validate(case_hash, board_hash)
    #processing neg_list
    neg_list.each do |k|
        if case_hash.has_key?(k) 
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
            if k == "arch_whitelist" and case_hash[k].include?(board_hash["arch"])
                return true
            else
                return false
            end
            if k == "platform_whitelist" and case_hash[k].include?(board_hash["identifier"])
                return true
            else
                return false
            end
        end
    end
    #processing neural_list
    neural_list.each do |k|
        if case_hash.has_key?(k)
            if k == "min_ram" and board_hash.has_key?("ram") and case_hash[k].to_i > board_hash["ram"].to_i
                return false
            end
            if k == "min_flash" and board_hash.has_key?("flash") and case_hash[k].to_i > board_hash["falsh"].to_i
                return false
            end
            if k == "depends_on" and board_hash.has_key?("supported")
              case_hash[k].split().each do |k|
                if ! board_hash["supported"].include?(k)
                  return false
                end
              end
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
    ["min_ram", "min_flash", "depends_on"]
  end
  module_function :neural_list

  def get_board_name(instr)
    filter_list = [/_samples$/, /_samples2$/, /_kernel$/, /_usb$/, /_drivers$/, /_drivers$/]
    temp_str = instr.dup
    filter_list.each do |f|
      temp_str.gsub!(f, '')
    end
    temp_str
  end
  module_function :get_board_name

end