defprotocol Monad do
  def flat_map(wrapped_value, function)
end
