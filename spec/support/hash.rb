Hash.class_eval do
  def deep_merge(hsh)
    merger = proc do |key, v1, v2|
      v1.kind_of?(Hash) && v2.kind_of?(Hash) ? v1.merge(v2, &merger) : v2
    end
    self.merge(hsh, &merger)
  end
end
