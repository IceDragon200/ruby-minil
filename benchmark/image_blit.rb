require_relative "benchmark_helper"

img1 = Image.create(800, 600)
img2 = Image.create(800, 600)
iterations = 4

Benchmark.bmbm do |x|
  x.report("#blit") do
    iterations.times { img1.blit(img2, 0, 0, 0, 0, img2.width, img2.height) }
  end

  x.report("#rb_blit") do
    iterations.times { img1.rb_blit(img2, 0, 0, 0, 0, img2.width, img2.height) }
  end

  x.report("#alpha_blit") do
    iterations.times { img1.alpha_blit(img2, 0, 0, 0, 0, img2.width, img2.height) }
  end

  x.report("#rb_alpha_blit") do
    iterations.times { img1.rb_alpha_blit(img2, 0, 0, 0, 0, img2.width, img2.height) }
  end
end
