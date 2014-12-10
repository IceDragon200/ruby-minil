require 'minil/layout/functions'

module Minil
  module Layout
    def gauge0(v = false)
      fill(:c1)
    end

    def gauge1(v = false)
      chain(
        gradient(:c1, :c2, v),
        contract(1, chain(clear, gradient(:c3, :c4, v))),
        split(v, alpha_blend(fill(:hg)), null)
      )
    end

    def gauge2(v = false)
      chain(
        split(v, gradient(:c1, :c2, v), gradient(:c2, :c1, v)),
        contract(1, chain(clear,
                          split(v, gradient(:c3, :c4, v),
                                   gradient(:c4, :c3, v)))),
        split(v, alpha_blend(fill(:hg)), null)
      )
    end

    def gauge3(v = false)
      split(v, fill(:c1), fill(:c3), fill(:c2), fill(:c4))
    end

    def gauge4(v = false)
      padded_flat(:c1, :c3)
    end

    def gauge5(v = false)
      split(v, padded_flat(:c1, :c3), padded_flat(:c2, :c4))
    end

    def gauge6(v = false)
      chain(fill(:c2),
            contract(1, chain(fill(:c4),
                              chain(fill(:c1),
                                    contract(1, fill(:c3))))))
    end

    def gauge7(v = false)
      chain(
        gradient(:c1, :c2, v),
        contract(1, chain(clear, gradient(:c3, :c4, v))),
        alpha_blend(split(v, gradient(:hg, :hg2, v), gradient(:hg2, :hg, v)))
      )
    end

    def gauge8(v = false)
      chain(
        gradient(:c1, :c2, v),
        contract(1, chain(clear,
                          split(v, gradient(:c3, :c4, v),
                                   gradient(:c4, :c3, v)))),
        alpha_blend(split(v, gradient(:hg, :hg2, v), gradient(:hg2, :hg, v)))
      )
    end

    def gauge9(v = false, r = 0.60)
      chain(
        slice(v, r, padded_flat(:c1, :c3), padded_flat(:c2, :c4)),
        alpha_blend(split(v, gradient(:hg, :hg2, v), gradient(:hg2, :hg, v)))
      )
    end
  end
end
