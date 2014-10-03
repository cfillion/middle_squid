module MiddleSquid
  Error = Class.new RuntimeError
  InvalidURIError = Class.new Addressable::URI::InvalidURIError
end
