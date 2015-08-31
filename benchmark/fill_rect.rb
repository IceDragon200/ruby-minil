require_relative "benchmark_helper"

img1 = Image.create(800, 600)
color = 0xFFFFFFFF
iterations = 10

Benchmark.bmbm do |x|
  x.report("#fill_rect") do
    iterations.times { img1.fill_rect(0, 0, img1.width, img1.height, color) }
  end

  x.report("#rb_fill_rect") do
    iterations.times { img1.rb_fill_rect(0, 0, img1.width, img1.height, color) }
  end

  x.report("#fill") do
    iterations.times { img1.fill(color) }
  end

  x.report("#rb_fill") do
    iterations.times { img1.rb_fill(color) }
  end
end
