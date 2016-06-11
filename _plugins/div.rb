
module Jekyll
  module DivisionFilter
    def div(num, denom)
      num.to_f / denom.to_f
    end
  end
end

Liquid::Template.register_filter(Jekyll::DivisionFilter)
