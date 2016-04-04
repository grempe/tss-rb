# Common utility and math functions
module Util
  # The EXP table.  The elements are to be read from top to
  # bottom and left to right.  For example, EXP[0] is 0x01, EXP[8] is
  # 0x1a, and so on. Note that the EXP[255] entry is present only as a
  # placeholder, and is not actually used in any computation.
  EXP = [0x01, 0x03, 0x05, 0x0f, 0x11, 0x33, 0x55, 0xff,
       0x1a, 0x2e, 0x72, 0x96, 0xa1, 0xf8, 0x13, 0x35,
       0x5f, 0xe1, 0x38, 0x48, 0xd8, 0x73, 0x95, 0xa4,
       0xf7, 0x02, 0x06, 0x0a, 0x1e, 0x22, 0x66, 0xaa,
       0xe5, 0x34, 0x5c, 0xe4, 0x37, 0x59, 0xeb, 0x26,
       0x6a, 0xbe, 0xd9, 0x70, 0x90, 0xab, 0xe6, 0x31,
       0x53, 0xf5, 0x04, 0x0c, 0x14, 0x3c, 0x44, 0xcc,
       0x4f, 0xd1, 0x68, 0xb8, 0xd3, 0x6e, 0xb2, 0xcd,
       0x4c, 0xd4, 0x67, 0xa9, 0xe0, 0x3b, 0x4d, 0xd7,
       0x62, 0xa6, 0xf1, 0x08, 0x18, 0x28, 0x78, 0x88,
       0x83, 0x9e, 0xb9, 0xd0, 0x6b, 0xbd, 0xdc, 0x7f,
       0x81, 0x98, 0xb3, 0xce, 0x49, 0xdb, 0x76, 0x9a,
       0xb5, 0xc4, 0x57, 0xf9, 0x10, 0x30, 0x50, 0xf0,
       0x0b, 0x1d, 0x27, 0x69, 0xbb, 0xd6, 0x61, 0xa3,
       0xfe, 0x19, 0x2b, 0x7d, 0x87, 0x92, 0xad, 0xec,
       0x2f, 0x71, 0x93, 0xae, 0xe9, 0x20, 0x60, 0xa0,
       0xfb, 0x16, 0x3a, 0x4e, 0xd2, 0x6d, 0xb7, 0xc2,
       0x5d, 0xe7, 0x32, 0x56, 0xfa, 0x15, 0x3f, 0x41,
       0xc3, 0x5e, 0xe2, 0x3d, 0x47, 0xc9, 0x40, 0xc0,
       0x5b, 0xed, 0x2c, 0x74, 0x9c, 0xbf, 0xda, 0x75,
       0x9f, 0xba, 0xd5, 0x64, 0xac, 0xef, 0x2a, 0x7e,
       0x82, 0x9d, 0xbc, 0xdf, 0x7a, 0x8e, 0x89, 0x80,
       0x9b, 0xb6, 0xc1, 0x58, 0xe8, 0x23, 0x65, 0xaf,
       0xea, 0x25, 0x6f, 0xb1, 0xc8, 0x43, 0xc5, 0x54,
       0xfc, 0x1f, 0x21, 0x63, 0xa5, 0xf4, 0x07, 0x09,
       0x1b, 0x2d, 0x77, 0x99, 0xb0, 0xcb, 0x46, 0xca,
       0x45, 0xcf, 0x4a, 0xde, 0x79, 0x8b, 0x86, 0x91,
       0xa8, 0xe3, 0x3e, 0x42, 0xc6, 0x51, 0xf3, 0x0e,
       0x12, 0x36, 0x5a, 0xee, 0x29, 0x7b, 0x8d, 0x8c,
       0x8f, 0x8a, 0x85, 0x94, 0xa7, 0xf2, 0x0d, 0x17,
       0x39, 0x4b, 0xdd, 0x7c, 0x84, 0x97, 0xa2, 0xfd,
       0x1c, 0x24, 0x6c, 0xb4, 0xc7, 0x52, 0xf6, 0x00].freeze

  # The LOG table. The elements are to be read from top to
  # bottom and left to right. For example, LOG[1] is 0, LOG[8] is 75,
  # and so on. Note that the LOG[0] entry is present only as a
  # placeholder, and is not actually used in any computation.
  LOG = [0,     0,   25,    1,   50,    2,   26,  198,
       75,  199,   27,  104,   51,  238,  223,    3,
       100,   4,  224,   14,   52,  141,  129,  239,
       76,  113,    8,  200,  248,  105,   28,  193,
       125, 194,   29,  181,  249,  185,   39,  106,
       77,  228,  166,  114,  154,  201,    9,  120,
       101,  47,  138,    5,   33,   15,  225,   36,
       18,  240,  130,   69,   53,  147,  218,  142,
       150, 143,  219,  189,   54,  208,  206,  148,
       19,   92,  210,  241,   64,   70,  131,   56,
       102, 221,  253,   48,  191,    6,  139,   98,
       179,  37,  226,  152,   34,  136,  145,   16,
       126, 110,   72,  195,  163,  182,   30,   66,
       58,  107,   40,   84,  250,  133,   61,  186,
       43,  121,   10,   21,  155,  159,   94,  202,
       78,  212,  172,  229,  243,  115,  167,   87,
       175,  88,  168,   80,  244,  234,  214,  116,
       79,  174,  233,  213,  231,  230,  173,  232,
       44,  215,  117,  122,  235,   22,   11,  245,
       89,  203,   95,  176,  156,  169,   81,  160,
       127,  12,  246,  111,   23,  196,   73,  236,
       216,  67,   31,   45,  164,  118,  123,  183,
       204, 187,   62,   90,  251,   96,  177,  134,
       59,   82,  161,  108,  170,   85,   41,  157,
       151, 178,  135,  144,   97,  190,  220,  252,
       188, 149,  207,  205,   55,   63,   91,  209,
       83,   57,  132,   60,   65,  162,  109,   71,
       20,   42,  158,   93,   86,  242,  211,  171,
       68,   17,  146,  217,   35,   32,   46,  137,
       180, 124,  184,   38,  119,  153,  227,  165,
       103,  74,  237,  222,  197,   49,  254,   24,
       13,   99,  140,  128,  192,  247,  112,    7].freeze

  # The addition operation returns the Bitwise
  # Exclusive OR (XOR) of its operands.
  def self.gf256_add(a, b)
    a ^ b
  end

  # The subtraction operation is identical, because the field has
  # characteristic two.
  def self.gf256_sub(a, b)
    gf256_add(a, b)
  end

  # The multiplication operation takes two elements X and Y as input and
  # proceeds as follows.  If either X or Y is equal to 0x00, then the
  # operation returns 0x00.  Otherwise, the value EXP[ (LOG[X] + LOG[Y])
  # modulo 255] is returned.
  def self.gf256_mul(x, y)
    return 0 if x == 0 || y == 0
    EXP[(LOG[x] + LOG[y]) % 255]
  end

  # The division operation takes a dividend X and a divisor Y as input
  # and computes X divided by Y as follows.  If X is equal to 0x00, then
  # the operation returns 0x00.  If Y is equal to 0x00, then the input is
  # invalid, and an error condition occurs.  Otherwise, the value
  # EXP[(LOG[X] - LOG[Y]) modulo 255] is returned.
  def self.gf256_div(x, y)
    return 0 if x == 0
    raise Tss::Error, 'divide by zero' if y == 0
    EXP[(LOG[x] - LOG[y]) % 255]
  end

  # Share generation Functions
  ############################

  # We first define how to share a single octet.
  #
  # The function f takes as input a single octet X that is not equal to
  # 0x00, and an array A of M octets, and returns a single octet.  It is
  # defined as:
  #
  #   f(X, A) =  GF_SUM A[i] (*) X^i
  #              i=0,M-1
  #
  # Because the GF_SUM summation takes place over GF(256), each addition
  # uses the exclusive-or operation, and not integer addition.  Note that
  # the successive values of X^i used in the computation of the function
  # f can be computed by multiplying a value by X once for each term in
  # the summation.
  def self.f(x, bytes)
    raise Tss::Error, 'invalid share index value, cannot be 0' if x == 0
    y = 0
    x_i = 1

    bytes.each do |b|
      y = gf256_add(y, gf256_mul(b, x_i))
      x_i = gf256_mul(x_i, x)
    end

    y
  end

  # Secret Reconstruction Functions
  # ###############################

  # We define the function L_i (for i from 0 to M-1, inclusive) that
  # takes as input an array U of M pairwise distinct octets, and is
  # defined as
  #
  #                             U[j]
  #   L_i(U) = GF_PRODUCT   -------------
  #            j=0,M-1, j!=i  U[j] (+) U[i]
  #
  # Here the product runs over all of the values of j from 0 to M-1,
  # excluding the value i.  (This function is equal to ith Lagrange
  # function, evaluated at zero.)  Note that the denominator in the above
  # expression is never equal to zero because U[i] is not equal to U[j]
  # whenever i is not equal to j.
  #
  def self.basis_poly(i, u)
    prod = 1

    (0..(u.length - 1)).each do |j|
      next if i == j
      prod = gf256_mul(prod, gf256_div(u[j], gf256_add(u[j], u[i])))
    end

    prod
  end

  # We denote the interpolation function as I. This function takes as
  # input two arrays U and V, each consisting of M octets, and returns a
  # single octet; it is defined as:
  #
  #   I(U, V) =  GF_SUM  L_i(U) (*) V[i].
  #              i=0,M-1
  #
  def self.lagrange_interpolation(u, v)
    sum = 0

    (0..(v.length - 1)).each do |i|
      sum = gf256_add(sum, gf256_mul(basis_poly(i, u), v[i]))
    end

    sum
  end

  # Conversion Functions
  ######################

  # String to Byte Array
  def self.utf8_to_bytes(str)
    str.bytes.to_a
  end

  # Byte Array to String
  def self.bytes_to_utf8(bytes)
    bytes.pack('C*').force_encoding('utf-8')
  end

  def self.bytes_to_hex(bytes)
    hex = ''
    bytes.each { |b| hex += sprintf('%02x', b).upcase }
    hex
  end

  def self.hex_to_bytes(str)
    # clone so we don't destroy the original string passed in by slicing it.
    strc = str.clone
    bytes = []
    len = strc.length
    raise Tss::Error, 'invalid hex value, cannot be an odd length' if len.odd?
    # slice off two hex chars at a time and convert them to an Integer Byte.
    (len / 2).times { bytes << strc.slice!(0, 2).hex }
    bytes
  end

  def self.hex_to_utf8(hex)
    bytes_to_utf8(hex_to_bytes(hex))
  end

  def self.utf8_to_hex(str)
    bytes_to_hex(utf8_to_bytes(str))
  end
end
