class TestException < StandardError
  def backtrace
    %w(line1 line2 line3)
  end
end
