require 'date'

class SgStrangeCalendar
  # カレンダー上の配置を表す構造体
  # 1月の、日曜日を起点として4日目であればCalendarPos.new(1,4)と表す(1-index)
  CalendarPos = Struct.new(:month, :dayCount)

  WEEKDAYS = %w[Su Mo Tu We Th Fr Sa]
  MONTHS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]

  def initialize(year, today = nil)
    @year = year
    # カレンダー上の配置をキー、Dateオブジェクトを値としたハッシュ
    # rawCalendar[CalendarPos(1,10)]でDateオブジェクトを取得できる
    # 対応する日付が存在しない場合はnilが返ってくる
    @raw_calendar = (1..12).flat_map do | month |
      firstDay = Date.new(year, month, 1)
      lastDay = Date.new(year, month, -1)
      offset = firstDay.wday # 日曜日が0
      (firstDay..lastDay).map.with_index(1) do | date, count |
        [CalendarPos.new(month, offset + count), date]
      end
    end.to_h

    @prettyPrinter = HighlightPrinter.new(2, today)
  end

  def horizontal_header
    "#{@year} #{all_weekdays.join(" ")}"
  end

  def vertical_header
    "#{@year} #{MONTHS.join(" ")}"
  end

  # カレンダーに表示する曜日(文字列)を全て収めた配列を返す
  def all_weekdays
    WEEKDAYS * 5 + WEEKDAYS[0, 2]
  end

  def generate(vertical: false)
    vertical ? generate_vertical : generate_horizontal
  end

  def generate_vertical
    calendar = vertical_header
    calendar << "\n"
    lines = all_weekdays.map.with_index(1) do | weekday, index |
      line = "#{weekday}    #{
        (1..12).map do | month |
          date = @raw_calendar[CalendarPos.new(month, index)]
          @prettyPrinter.print(date)
        end.join("  ")}"
      adjust_space(line)
    end
    calendar << lines.join("\n")
    calendar
  end

  def generate_horizontal
    calendar = horizontal_header
    calendar << "\n"
    lines = (1..12).map do | month |
      month_index = month - 1
      line = "#{MONTHS[month_index]}  #{
        all_weekdays.map.with_index(1) do | _, index |
          date = @raw_calendar[CalendarPos.new(month, index)]
          @prettyPrinter.print(date)
        end.join(" ")}"
      adjust_space(line)
    end
    calendar << lines.join("\n")
    calendar
  end

  # 日付間のスペースや、行末の不要なスペースを除去して、各行の出力を確定させる
  def adjust_space(line)
      line = line.gsub(/ (\[\d{2}\])/) { $1 } # [10]のような2桁パターンの前スペースを削除して詰める
      line = line.gsub("] ", "]") # 桁数関係なく]の後置スペースは詰める
      line.strip
  end
end

class WithPaddingPrinter
  def initialize(padding)
    @padding = padding
    @blank = " " * padding
  end

  # Dateかnilを受け取り、日付をパディングで埋めて返す
  def print(date)
    return @blank if date.nil?

    date.day.to_s.rjust(@padding, ' ')
  end
end

class HighlightPrinter < WithPaddingPrinter
  def initialize(padding, today=nil)
    super(padding)
    @today = today
  end

  def print(date)
    return super(date) if @today.nil? || date != @today

    "[#{date.day}]"
  end
end
