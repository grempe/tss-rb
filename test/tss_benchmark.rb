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
      TSS.split(secret: 'secret', threshold: n, num_shares: n, hash_alg: 'SHA256')
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
      TSS.split(secret: @secret, threshold: 3, num_shares: 3, hash_alg: 'SHA256')
    end
  end
end

# when combining shares, vary the number of shares passed in to be processed
class CombineBenchmarkNumShares < Minitest::Benchmark
  def self.bench_range
    bench_linear(8, 255, 8)
  end

  def setup
    @s = TSS.split(secret: SecureRandom.hex(32), threshold: 8, num_shares: 255, hash_alg: 'SHA256')
  end

  def bench_tss_combine_num_shares
    assert_performance_constant(0.900) do |n|
      TSS.combine(shares: @s.sample(n))
    end
  end
end
