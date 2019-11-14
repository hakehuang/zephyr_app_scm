require 'yaml'
require 'awesome_print'
require 'rly'
require 'ruby_parser'
require 'logger'

=begin
expression “and” expression
expression “or” expression
“not” expression
“(” expression “)”
symbol “==” constant
symbol “!=” constant
symbol “<” number
symbol “>” number
symbol “>=” number
symbol “<=” number
symbol “in” list
symbol “:” string
symbol
=end

$log = Logger.new(STDOUT)
$log.level = Logger::WARN

class ZephyrLex < Rly::Lex

  literals "=+><():[],\";\'"
  ignore "\' \"\t\n\\"
  token :AND, /(and|AND)/ do |t|
    t
  end

  token :OR, /(or|OR)/ do |t|
    t
  end

  token :IN, /(in|IN)/ do |t|
    t
  end

  token :NOT, /(not|NOT)/ do |t|
    t
  end

  token :HEX, /0x[0-9a-fA-F]+/ do |t|
    t.value = t.value.to_i(16)
    t
  end

  token :NUMBER, /\d+/ do |t|
    t.value = t.value.to_i
    t
  end

  token :EQUATE, /==/ do |t|
    t
  end

  token :NOEQUATE, /\!=/ do |t|
    t
  end

  token :GTE, />=/ do |t|
    t
  end

  token :LTE, /<=/ do |t|
    t
  end

  token :DATA, /[a-zA-Z_][a-zA-Z0-9_-]*\.[a-zA-Z_]*/ do |t|
    t
  end

  token :DATA, /[a-zA-Z_][a-zA-Z0-9_-]*/ do |t|
    t
  end

  on_error do |t|
    puts "Illegal character #{t.value}"
    t.lexer.pos += 1
    nil
  end

  def show()
    while tok = self.next do
        puts "#{tok.type} -> #{tok.value}"
    end
  end
end

class String
    def AND(v)
        tv1 = [self]
        tv2 = []
        if v.class == Array
            tv2 = v
        else
            tv2 = [v]
        end    
        return ["AND"] | tv1 | tv2
    end

    def OR(v)
        tv1 = [self]
        tv2 = []
        if v.class == Array
            tv2 = v
        else
            tv2 = [v]
        end    
        return ['OR'] | tv1 | tv2
    end

    def NOT()
        return ["NOT"]| [self]
    end
end

class Array
    def AND(v)
        tv2 = []
        if v.class == Array
            tv2 = v
        else
            tv2 = [v]
        end    
        return ["AND"] | self | tv2
    end

    def OR(v)
        tv2 = []
        if v.class == Array
            tv2 = v
        else
            tv2 = [v]
        end    
        return ["OR"] | self | tv2
    end

    def NOT()
        return ["NOT"] | self
    end
end

class Hash
    def AND(v)
        tv2 = []
        if v.class == Array
            tv2 = v
        else
            tv2 = [v]
        end    
        return ["AND"] | [self] | tv2
    end

    def OR(v)
        tv2 = []
        if v.class == Array
            tv2 = v
        else
            tv2 = [v]
        end    
        return ["OR"] | [self] | tv2
    end

    def NOT()
        tv1 = [ ]
        if self == Array
            tv1 = self
        else
            tv1 = [self]
        end
        return ["NOT"] | tv1
    end
end

class ZephyrParse < Rly::Yacc
  def names
    @names ||= {}
  end

  rule 'statement : expression' do |st, e|
    st.value = e.value
    $log.info  "rule statement expression #{st.value}"
  end

  rule 'statement : DATA "=" expression' do |st, n, _, e|
    self.names[n.value] = e.value
    st.value = self.names
  end

  rule 'expression : expression AND expression
                   | expression OR expression' do |ex, e1, op, e2|
    ex.value = e1.value.send(op.value.upcase(), e2.value)
    $log.info  "rule and or  #{ex.value}"
  end


  rule 'expression : expression EQUATE expression
                   | expression NOEQUATE expression
                   | expression ">" expression
                   | expression "<" expression
                   | expression GTE expression
                   | expression LTE expression' do |ex, e1, op, e2|
    ex.value = { op.value => [e1.value, e2.value]}
    $log.info  "rule ops  #{ex.value}"
  end
                   

  rule 'expression : NOT expression' do |ex, op, e|
    ex.value = e.value.send(op.value.upcase())
  end
 
  rule 'expression : IN expression' do |ex, _, e|
    ex.value = e.value
  end  

  rule 'expression : "[" expression "]"' do |ex, _, e, _|
    ex.value = e.value
    $log.info  "rule []  #{ex.value}"
  end
 
  rule 'expression : "(" expression ")"' do |ex, _, e, _|
    ex.value = [e.value]
    $log.info  "rule ()  #{ex.value}"
  end

  rule 'expression : expression "," expression
                   | expression ";" expression
                   | expression " " expression' do |ex, e1, op, e2|
    tv1 = [ ]
    if e1.value.class == Array
        tv1 = e1.value
    else
        tv1 = [e1.value]
    end
    tv2 = []
    if e2.value.class == Array
        tv2 = e2.value
    else
        tv2 = [e2.value]
    end
    ex.value = tv1 | tv2
    $log.info  "rule ,  #{ex.value}"
  end

  rule 'expression : DATA "(" expression ")" ' do |ex, d, _, e, _|
    ex.value = {d.value => e.value }
    $log.info  "rule DATA expression  #{ex.value}"
  end

  rule 'expression : NUMBER' do |ex, n|
    ex.value = n.value
    $log.info  "rule NUMBER  #{ex.value}"
  end

  rule 'expression : DATA' do |ex, n|
    ex.value = n.value
    $log.info  "rule DATA  #{ex.value}"
  end

  rule 'expression : HEX' do |ex, n|
    ex.value = n.value
    $log.info  "rule HEX  #{ex.value}"
  end

  rule 'expression : expression "+" expression
                   | expression "*" expression
                   | expression "/" expression' do |ex, e1, op, e2|
    ex.value = e1.value.send(op.value, e2.value)
    $log.info  "rule +*/  #{ex.value}"
  end

  rule 'expression : expression "-" expression' do |ex, e1, op, e2|
    $log.info  "#{e1.value}  #{ex.value} #{e2.value}"
    ex.value = e1.value + op.value + e2.value
    $log.info  "rule -  #{ex.value}"
  end

  #store_grammar 'grammar.txt'

end

def isDT_filter(key)
  dt_list = ["dt_compat_enabled", "dt_alias_exists", "dt_compat_enabled_with_alias"]
  if dt_list.include?(key)
    return true
  end
  return false
end

def dt_parser(k, v, board_hash)
  if k == "dt_compat_enabled"
      return false 
  elsif k == "dt_alias_exists"
      return false
  elsif k == "dt_compat_enabled_with_alias"
      return false
  end
end

def simple_ast(data, board_hash)
  configs = board_hash["configs"]
  case data.class.name
      when "Hash"
          data.each do |k, v|
            if isDT_filter(k)
              return dt_parser(k, v, board_hash)
            end
            if board_hash.has_key?(k)
              return eval "#{board_hash[k]} #{v[0]} #{simple_ast[v[1], board_hash]}"
            end
            if configs.has_key?(k)
              return eval "#{board_hash[k]} #{v[0]} #{simple_ast[v[1], board_hash]} "
            end
            if board_hash["settings"] and board_hash["settings"].has_key?(k)
              bv = board_hash["settings"][k]
              return eval "#{bv} #{v[0]} #{simple_ast[v1, board_hash]}"
            end
          end
          return false
      when "Array"
          judge = configs.keys()
=begin
          if board_hash["settings"] and board_hash["settings"]["no_filter"]
              judge = board_hash["settings"]["no_filter"]
              #puts "judge is #{judge}"
          else
              return true
          end
=end
          case data[0]
              when "AND"
                  data[1..-1].each do |dst|
                    case dst.class.name
                      when "String"
                        if judge and ! judge.include?(dst)
                          return false
                        end
                      else
                        return false if ! simple_ast(dst, board_hash)
                    end
                  end
                  return true
              when "OR"
                data[1..-1].each do |dst|
                  case dst.class.name
                    when "String"
                      if judge and judge.include?(dst)
                        return true
                      end
                    else
                      if simple_ast(dst, board_hash)
                        return true
                      end
                  end
                end
                return false
              when "NOT"
                data[1..-1].each do |dst|  
                  case dst.class.name
                    when "String"
                      if judge and judge.include?(dst)
                        return false
                      end
                    else
                      if simple_ast(dst, board_hash)
                        return false
                      end
                  end                  
                end
                return true
          end
      else
          #puts "class is #{data.class}"
          return data
  end
end

def zephyr_filter_parser(filters, board_hash)
    parser = ZephyrParse.new(ZephyrLex.new)
    data = parser.parse(filters)
    if data.class == String
        if board_hash["settings"] and board_hash["settings"]["no_filter"]
            if board_hash["settings"]["no_filter"].include?(data)
                return false
            else
                return true
            end
        else
            return true
        end
    else
        return simple_ast(data, board_hash)
    end
end

def zephyr_expr_parser(expr)
    parser = ZephyrParse.new(ZephyrLex.new)
    ret = []
    expr.split().each do |expr|
      ret = ret | [parser.parse(expr)]
    end
    return ret
end


if __FILE__ == $0
    #lex = ZephyrLex.new('C and A or B == D != E > 12 < >= <= in NOT ( f )')
    #lex = ZephyrLex.new('[ 1, 2, 3 ]')
    #lex = ZephyrLex.new('C = 0x1234')
    #lex.show()
    $log.level = Logger::INFO
    parser = ZephyrParse.new(ZephyrLex.new)
    board_hash = {"configs" => {"CONFIG_ARM"=>"y", "CONFIG_CORTEX_M_SYSTICK"=>"y",
      "CONFIG_SOC_SERIES_KINETIS_K8X"=>"y", "CONFIG_SOC_MK82F25615"=>"y",
      "CONFIG_BOARD_FRDM_K82F"=>"y", "CONFIG_SERIAL"=>"y", "CONFIG_CONSOLE"=>"y",
      "CONFIG_UART_CONSOLE"=>"y", "CONFIG_UART_INTERRUPT_DRIVEN"=>"y",
      "CONFIG_PINMUX"=>"y", "CONFIG_GPIO"=>"y",
      "CONFIG_SYS_CLOCK_HW_CYCLES_PER_SEC"=>"120000000", "CONFIG_OSC_LOW_POWER"=>"y", "CONFIG_ARM_MPU"=>"y"} }
=begin  
    $log.info  parser.parse('A AND B')
    $log.info  parser.parse('NOT A')
    $log.info  parser.parse('(A)')
    $log.info  parser.parse('2+2')
    $log.info  parser.parse('A = (2+2) ')
    $log.info  parser.parse("[1,2,3]")
    $log.info  parser.parse("NOT (A AND B)")
    $log.info  parser.parse("IN [\"A\", \"B\", \"C\"]")
    $log.info  parser.parse("SAND != GOLD")
    $log.info  parser.parse("SAND == GOLD")
    $log.info  parser.parse("SAND == 4")
    $log.info  parser.parse("(SAND < 4)")
    $log.info  parser.parse("(SAND < 4) AND (SAND > 1)")
    $log.info  parser.parse("(SAND <= 4) AND (SAND >= 1)")
    $log.info  parser.parse("(SAND <= 4) OR (SAND >= 1)")
    $log.info  parser.parse("C == 0xA")

    $log.info  zephyr_filter_parser("CONFIG_ARCH_HAS_USERSPACE", board_hash)
    lex = ZephyrLex.new('dt_compat_enabled\(\"jedec,spi-nor\"\)')
    lex.show()
    $log.info  zephyr_filter_parser("dt_compat_enabled(\"jedec, spi-nor\")", board_hash)
    lex = ZephyrLex.new('dt_compat_enabled_with_alias("gpio-keys", "sw0")')
    lex.show()
    $log.info  zephyr_filter_parser('dt_compat_enabled_with_alias("gpio-keys", "sw0")', board_hash)
    $log.info  zephyr_filter_parser("CONFIG_CPU_ARCV2 and CONFIG_CPU_HAS_FPU", board_hash)
    $log.info  zephyr_filter_parser("CONFIG_ENTROPY_HAS_DRIVER", board_hash)
    $log.info  parser.parse("CONF_FILE='common.conf;mt.conf;no-preempt.conf;no-timers.conf;arm.conf'")
    $log.info  parser.parse("(CONFIG_MP_NUM_CPUS > 1) and not CONFIG_ARC")
    $log.info  zephyr_expr_parser("SHIELD=frdm_cr20a OVERLAY_CONFIG=overlay-802154.conf")


    $log.info  zephyr_filter_parser("(CONFIG_MP_NUM_CPUS > 1) and not CONFIG_ARC", board_hash)
=end

    $log.info  zephyr_filter_parser("CONFIG_X86 or (CONFIG_ARM and (CONFIG_SOC_MK64F12 or CONFIG_SOC_SERIES_SAM3X)) or CONFIG_ARCH_POSIX", board_hash)

end
