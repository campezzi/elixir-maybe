defprotocol Applicative do
  def ap(wrapped_value, wrapped_function)
end
