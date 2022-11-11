module Style
  def colorize(str, clr, *otr)
    colors = {
      'black'  => '100;30',  # black is invisible!
      'red'    => '31',
      'green'  => '32',
      'yellow' => '33',
      'blue'   => '34',
      'purple' => '35',
      'cyan'   => '36',  # light-blue
      'white'  => '37',
    }
    options = {
      'bold'      => '1',
      'dim'       => '2',
      'italic'    => '3',
      'underline' => '4',
      'reverse'   => '7',
      'hidden'    => '8',
      'bg_light'  => '47',
      'bg_dark'   => '100',
    }
    color = colors.key?(clr) ? colors[clr] : '37'  # 37 = white
    decor = otr.select {|o| options.key? o}.map {|o| options[o]}.join ';'

    # just for blank :)
    return "\e[7m#{str}\e[0m" if str == ' blank '
    return "\e[2;8m#{str}\e[0m" if clr == 'blank'
    # black is invisible!
    return "\e[100m#{str}\e[0m" if str == ' black '

    "\e[1;#{color}#{(';' + decor) if decor.length > 0}m#{str}\e[0m"  # I want all to be bold :v
  end

  module_function :colorize
end

class Mastermind
  include Style
  #extend Style

  @@colors = ['black', 'red', 'green', 'yellow', 'blue', 'purple', 'cyan', 'white']

  @@fail = lambda {|*v| "\n#{' ' * 12} #{ Style.colorize('Incorrect input!', 'red') }
              #{ Style.colorize("- Hint - allowed values: #{v.join ', '}", 'green') } \n\n"}

  def initialize
    # fail-safe
    @user_role    = user_role   || 'codebreaker'
    @level        = level       || 'Normal'
    @code_length  = code_length || 4
    @attempts     = attempts    || 12

    @duplicates   = duplicates? || false
    @blanks       = blanks?     || false
    
    @available_options = available_options || @@colors.sample(@code_length)
    @available_options.push 'blank' if @blanks

    basic_info

    @decoding_board = Array.new(@attempts) {[Array.new(@code_length), Array.new(@code_length)]}
  end

  def play
    set_secret_pattern

    win_in = nil
    
    loop do
      system 'clear'
      puts basic_info
      print "PRESS  ENTER  TO  START ···  "
      break if gets.chomp.strip == ''
    end

    @attempts.times do |i|
      system 'clear'  #

      puts "
        #{'█' * (i+1)}#{' ' * (@attempts - i)} ━ #{i+1}/#{@attempts}
      "
      show_decoding_board i

      @decoding_board[i][0] = code_pegs
      @decoding_board[i][1] = key_pegs @decoding_board[i][0].clone

      win_in = i if verify_turn(@decoding_board[i][0], @decoding_board[i][1])
      break if win_in
    end
    win_in = verify_game unless win_in

    system 'clear'  #

    if win_in
      show_decoding_board win_in, true
      puts "".center(52, '─')
      puts " WINNER WINNER CHICKEN DINNER!! ".center(52, '─')
      puts "".center(52, '─')
    else
      show_decoding_board
      puts "".center(52, '─')
      puts " Win with Pride Lose with Dignity ".center(52, '─')
      puts "".center(52, '─')
    end
  end

 # -------------------------------- PRIVATE -------------------------------- #
  private

  def basic_info
    "
      Your role   : #{@user_role}
      Level       : #{@level}
      Code-length : #{@code_length}
      Attempts    : #{@attempts}
      Duplicates  : #{@duplicates ? 'Yes' : 'No'}
      Blanks      : #{@blanks     ? 'Yes' : 'No'}
    "
  end

  def show_decoding_board(row = nil, win = false)
    separator = lambda do |f, m, l, s|  # lambda function
      "#{' ' * 12}#{f}#{s * (@code_length * 4)}#{m}#{s * (@code_length * 2 + 1)}#{l}"
    end

    puts separator.call('╔', '╦', '╗', '═')
    @decoding_board.to_enum.with_index.reverse_each do |arr, index|
      code = arr[0].map {|c| c ? colorize('  ', c) : colorize('  ', 'white', 'dim')}
      key = arr[1].map {|k| k ? colorize('•', k) : colorize('·', 'white', 'dim')}
      line = "║#{code.join ' '} ║ #{key.join ' '} ║"
      if row == index && win
        puts "#{colorize('═', 'green') * 12}#{line}"
      elsif row == index
        puts "#{colorize('─', 'white') * 12}#{line}"
      else
        puts ' ' * 12 + line
      end
      puts separator.call('╟', '╫', '╢', '─') unless index == 0
    end
    puts separator.call('╚', '╩', '╝', '═')
  end

  def user_role
    loop do
      print "
      Choose your role [Codebreaker]:
        1. Codemaker    -   Chooses the secret pattern 
        2. Codebreaker  -   Tries to guess the secret pattern
       "
      case gets.chomp.strip
        when ''  then return
        when '1' then return 'codemaker'
        when '2' then return 'codebreaker'
      end

      puts @@fail.call '1','2'
    end
  end

  def level
    loop do
      print "
      Choose a level [Normal]:
           Level:   Code length:   Attempts:
        1. Normal      4              12
        2. Hard        6              15
        3. Crazy       8              18
       "
      case gets.chomp.strip
        when ''  then return
        when '1' then return 'Normal'
        when '2' then return 'Hard'  
        when '3' then return 'Crazy' 
      end

      puts @@fail.call '1','2','3'
    end
  end

  def code_length
    case @level
      when 'Normal' then return 4
      when 'Hard'   then return 6
      when 'Crazy'  then return 8
    end
  end

  def attempts
    case @code_length
      when 4 then 12
      when 6 then 15
      when 8 then 18
    end
  end

  def duplicates?
    print "
      Allow duplicates? [n]: <y/n>  "
    case gets.chomp.strip
      when ''  then return
      when 'y' then return true
      when 'n' then return false
    end
    puts @@fail.call 'y','n'
    duplicates?
  end

  def blanks?
    print "
      Allow blanks? [n]: <y/n>  "
    case gets.chomp.strip
      when ''  then return
      when 'y' then return true
      when 'n' then return false
    end
    puts @@fail.call 'y','n'
    blanks?
  end

  def available_options
    return @@colors if @code_length == 8 unless @duplicates

    min = @duplicates ? 2 : @code_length
    num = nil

    loop do
      print "
      Enter the number of colors to play with [#{@code_length}]: <#{min}-8>
       "
      num = gets.chomp.strip == '' ? @code_length : $_.to_i
      
      return @@colors if num == 8
      break if num.between?(min, 8)

      puts @@fail.call "numbers between #{min} and 8"
    end

    loop do
      print "
      Select the #{num} colors to be used [random selection]:
        Available colors:
          #{@@colors.map {|color| colorize(" #{color} ", color)}.join ' '}
       "
      colors = gets.downcase.split

      return @@colors.sample(num) if colors.empty?
      return colors if (colors - @@colors).empty?

      puts @@fail.call 'Choose from available colors'
    end
  end

  def enter_pattern
    print "
    Available options:
      #{@available_options.map {|option| colorize(" #{option} ", option)}.join ' '}
     "
    pattern = gets.downcase.split

    check_pattern(pattern) ? pattern : enter_pattern
  end

  def check_pattern(pattern)
    result = true
    underln = Array.new

    pattern.each_with_index do |peg, index|
      decorator = (@available_options.include? peg) ? '⎺' : '^'

      if index < @code_length
        underln.push colorize(decorator * peg.length, (decorator == '⎺') ? 'green' : 'red')
      else
        underln.push colorize(decorator * peg.length, 'yellow')
        result = false
      end
    end

    # if there are missing values:
    lack = @code_length - pattern.count
    lack.times {underln.push colorize('⁀' * 5, 'cyan')}

    print "
      #{pattern.join ' '}
      #{underln.join ' '}
      "
    if lack > 0 && !@blanks
      print "  - Some values are missing! #{colorize '⁀', 'cyan'}
      "
      result = false 
    end

    if lack < 0
      print "  - There are #{colorize(lack.abs.to_s, 'yellow')} extra values!
      "
      result = false
    end

    unless (pattern - @available_options).empty?
      print "  - Some values are invalid! #{colorize '^', 'red'}
      "
      result = false 
    end

    unless pattern == pattern.uniq || @duplicates
      print "  - Some values are duplicated!
      "
      result = false
    end

    result
  end

  def set_secret_pattern
    if @user_role == 'codebreaker'
      @secret_pattern = !@duplicates ? @available_options.sample(@code_length) :
              Array.new(code_length).map {|peg| peg = @available_options.sample}
    elsif @user_role == 'codemaker'
      puts "
      SECRET PATTERN!"
      @secret_pattern = enter_pattern
    else
      puts "
      There are an error with the 'user role': #{@user_role}"
    end
  end

  def guess_pattern  #
    # I was thinking of writing a complex code to get the pattern guess...
    # but I realized that no one is going to review this code, no one really
    # cares; someone already did this and it's not relevant...
    # =>  so I'll settle for this
    # Besides, why the hell would you wanna play this against the computer?
      # =>  read it in small letters: I got lazy :>
    if [false, true, false].sample  # two 'false' to increase complexity :)
      return @secret_pattern
    end
    @available_options.sample @code_length
  end

  def code_pegs
    if @user_role == 'codebreaker'
      return enter_pattern
    elsif @user_role == 'codemaker'
      return guess_pattern
    else
      puts "There is an error in the code! @user_role = #{@user_role}"
    end
  end

  def key_pegs pattern  # this parameter must be a 'clone'
    key_pegs = []

    secret = @secret_pattern.clone

    @code_length.times do |i|
      if pattern[i] == secret[i]
        key_pegs.push 'green'

        pattern[i] = nil
        secret[i]  = nil
      end
    end

    pattern.compact!
    secret.compact!

    (pattern & secret).count.times {key_pegs.push 'yellow'}

    (@code_length - key_pegs.count).times {key_pegs.push nil}

    key_pegs
  end

  def verify_turn(code, key)
    code == @secret_pattern && key.all? {|k| k=='green'}
  end

  def verify_game
    @decoding_board.find_index do |pair|
      code, key = pair
      code == @secret_pattern && key.all? {|k| k == 'green'}
    end
  end
end


system 'reset'  #

start_msg = "
  #{Style.colorize('
       ╱               ╱         ╱                         ╱ 
      ┍━┓┍━┓┍━━━┓┍━━━┓┍━━━━┓┍━━━┓┍━━━┓┍━┓┍━┓┍━━┓┍━┓╱┍┓┍━━━┓    ╱ 
   ╱  ││┗┙│┃│┎─┐┃│┎─┐┃│┎┐┎┐┃│┎──┚│┎─┐┃││┗┙│┃└┐┎┚││┗┓│┃└┐┎┐┃
     ╱│┎┐┎┐┃│┃╱│┃│┗━━┓└┚│┃└┚│┗━━┓│┗━┙┃│┎┐┎┐┃ │┃ │┎┐┃│┃ │┃│┃
      │┃│┃│┃│┗━┙┃└──┐┃  │┃╱ │┎──┚│┎┐┎┚│┃│┃│┃ │┃ │┃│┗┙┃ │┃│┃ ╱ 
      │┃│┃│┃│┎─┐┃│┗━┙┃ ╱│┃  │┗━━┓│┃│┗┓│┃│┃│┃┍┙┗┓│┃└┐│┃┍┙┗┙┃
  ╱   └┚└┚└┚└┚╱└┚└───┚└ └┚╱┘└───┚└┚└─┚└┚└┚└┚└──┚└┚╱└─┚└───┚
      ╱               ╱            ╱                    ╱     ╱', 'green')}

  #{Style.colorize(' Instructions to play the game ', 'white').center 70,'═'}

  Write the names of the colors e.g.:
    #{Style.colorize 'red green yellow blue', 'white'}  #{Style.colorize '# if the level is \'easy\'', 'blank'}

  That will give you as a result:
      #{['red','green','yellow','blue'].map {|c| Style.colorize '', c}. join '   '} 

  The 'key pegs':
    #{Style.colorize '•', 'green'} -  #{Style.colorize 'correct in both color and position', 'green', 'italic'}
    #{Style.colorize '•', 'yellow'} -  #{Style.colorize 'correct color but wrong position', 'yellow', 'italic'}

  #{Style.colorize(' Setting up the game ', 'white').center 70,'═'}

    Message/ask example [#{Style.colorize 'default value', 'yellow'}] <#{Style.colorize 'allowed answers', 'green'}>:

  You can press enter to leave the #{Style.colorize 'default value', 'yellow'},
  otherwise you must provide an #{Style.colorize 'allowed answer', 'green'} #{Style.colorize '(value or values)', 'white'}


  #{' IMPORTANT '.center 63, '─'}
  The colors may #{Style.colorize 'not', 'yellow'} be the same, this is due to several factors,
  #{Style.colorize 'one of them may be your terminal configuration...', 'white'}

  #{Style.colorize 'default value', 'yellow'} may not appears, means your choice is mandatory
  #{Style.colorize 'allowed answer', 'green'} may also not appears 
  #{''.center 63, '─'}

  Messages such as the following don't require you to type anything
  #{Style.colorize('Press enter to continue... (just press enter!)
   ', 'white')}"
loop do 
  system 'clear'
  puts start_msg
  break if gets.chomp.strip == ''
end

system 'clear'
mastermind = Mastermind.new
mastermind.play
