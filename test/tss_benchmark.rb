require 'test_helper'
require 'minitest/benchmark'

# SEE : http://chriskottom.com/blog/2015/04/minitest-benchmark-an-introduction/
# SEE : http://chriskottom.com/blog/2015/05/minitest-benchmark-a-practical-example/

# vary the number of shares created while keeping the secret constant
class SplitBenchmarkNumShares < Minitest::Benchmark
  def self.bench_range
    bench_linear(1, 255, 8)
  end

  def bench_tss_split_num_shares
    assert_performance_linear(0.900) do |n|
      Splitter.new('secret', n, n, '123abc', 2).split
    end
  end
end

# vary the size of the secret while keeping the number of shares constant
class SplitBenchmarkSecretLength < Minitest::Benchmark
  def self.bench_range
    bench_linear(1, 65_534, 4096)
  end

  def bench_tss_split_secret_size
    assert_performance_linear(0.900) do |n|
      @secret = 'a' * n
      Splitter.new(@secret, 3, 3, '123abc', 2).split
    end
  end
end

# when combining shares, vary the number of shares passed in to be processed
class CombineBenchmarkNumShares < Minitest::Benchmark
  def self.bench_range
    bench_linear(8, 255, 8)
  end

  def setup
    @s = Splitter.new(SecureRandom.hex(32), 8, 255, '123abc', 2).split
  end

  def bench_tss_combine_num_shares
    assert_performance_linear(0.900) do |n|
      Combiner.new(@s.sample(n)).combine
    end
  end
end
