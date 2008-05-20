class Hash
  def filter(*keys)
    keys.flatten.inject({}) do |new_hash, key|
      new_hash[key] = self[key] if self[key]
      new_hash
    end
  end
  
  def stringify_keys!
    keys.each do |k|
      if k.is_a?(Symbol)
        value = delete(k)
        self[k.to_s] = value
      end
    end
  end
end