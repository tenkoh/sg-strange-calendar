require 'date'

class SgStrangeCalendar
  def initialize(year, today = nil)
    @year = year
    # カレンダー上の配置をキー、Dateオブジェクトを値としたハッシュを生成しておく。
    # rawCalendar[CalendarPos.new(1,10)]でDateオブジェクトを取得できる。
    # 対応する日付が存在しない場合はnilが返ってくる。
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

  def generate(vertical: false)
    vertical ? generate_vertical : generate_horizontal
  end

  private

  # カレンダー上の配置を表す構造体
  # 1月の、日曜日を起点として4日目であればCalendarPos.new(1,4)と表す(1-index)
  CalendarPos = Struct.new(:month, :day_count)

  WEEKDAYS = %w[Su Mo Tu We Th Fr Sa].freeze
  MONTHS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

  def horizontal_header
    "#{@year} #{display_weekdays.join(" ")}"
  end

  def vertical_header
    "#{@year} #{MONTHS.join(" ")}"
  end

  # カレンダーに表示する曜日(文字列)を全て収めた配列を返す
  def display_weekdays
    WEEKDAYS.cycle.take(37)
  end

  # 桁数調整や日付の協調表示を済ませた文字列を返す
  def get_pretty_date(month, day_count)
    @prettyPrinter.print(@raw_calendar[CalendarPos.new(month, day_count)])
  end

  def generate_vertical
    calendar_body = display_weekdays.map.with_index(1) do |weekday, index|
      days = (1..12).map { |month| get_pretty_date(month, index)}
      adjust_space("#{weekday}    #{days.join("  ")}")
    end
    [vertical_header, *calendar_body].join("\n")
  end

  def generate_horizontal
    calendar_body = (1..12).map do |month|
      month_index = month - 1
      days = display_weekdays.map.with_index(1) { |weekday, index| get_pretty_date(month, index)}
      adjust_space("#{MONTHS[month_index]}  #{days.join(" ")}")
    end
    [horizontal_header, *calendar_body].join("\n")
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
