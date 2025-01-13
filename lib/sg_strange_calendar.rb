require 'date'

class SgStrangeCalendar
  # カレンダー上の配置を表す構造体
  # 1月の、日曜日を起点として4日目であればCalendarPos.new(1,4)と表す(1-index)
  CalendarPos = Struct.new(:month, :dayCount)

  def initialize(year, today = nil)
    @weekdays = %w[Su Mo Tu We Th Fr Sa]
    @months = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
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

    @prettyPrinter = PrettyDayPrinter.new(2)
  end

  def horizontal_header
    "#{@year} #{all_weekdays.join(" ")}"
  end

  # カレンダーに表示する曜日(文字列)を全て収めた配列を返す
  def all_weekdays
    weekdays = @weekdays
    weekdays * 5 + weekdays[0, 2]
  end

  def generate(vertical: false)
    calendar = horizontal_header
    calendar << "\n"
    lines = (1..12).map do | month |
      month_index = month - 1
      line = @months[month_index]
      line << "  "
      line << all_weekdays.map.with_index(1) do | _, index |
        date = @raw_calendar[CalendarPos.new(month, index)]
        @prettyPrinter.pretty(date.nil? ? "" : date.day)
      end.join(" ")
      line.strip
    end
    calendar << lines.join("\n")
    calendar
  end
end

class PrettyDayPrinter
  def initialize(padding)
    @padding = padding
  end

  # 数字かnilを受け取り、to_sしてからパディングで埋めて返す
  def pretty(day)
    day.to_s.rjust(@padding, ' ')
  end
end
