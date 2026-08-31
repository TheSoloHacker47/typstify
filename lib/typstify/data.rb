# frozen_string_literal: true

require "json"
require "date"

module Typstify
  # Turns the `data:` you pass into the `data.json` a template reads.
  #
  # The validation pass exists so that a bad value fails immediately, naming the
  # exact key path, instead of surfacing later as a template that silently
  # renders "#<Invoice:0x00007f…>" — or, under Rails, as an empty object.
  #
  # That last case is the subtle one. ActiveSupport defines `as_json` on
  # `Object` itself, returning the instance variables of anything at all, so a
  # naive `respond_to?(:as_json)` check would happily serialise a Proc, an IO or
  # a half-built value object into `{}` and render a blank invoice. We therefore
  # accept `as_json` only from classes that actually define it — models,
  # serializers, Hash, Array, Time — and reject the generic fallback.
  module Data
    PRIMITIVES = [String, Integer, TrueClass, FalseClass, NilClass].freeze

    # `as_json` inherited from one of these is ActiveSupport's catch-all, not a
    # deliberate serialization.
    GENERIC_AS_JSON_OWNERS = [Object, Kernel, BasicObject].freeze

    module_function

    # @param data [Object] any JSON-serializable structure
    # @return [String] pretty JSON, ready to write as data.json
    # @raise [ArgumentError] naming the key path of the first bad value
    def dump(data)
      JSON.pretty_generate(normalize(data, ["data"]))
    end

    def normalize(value, path)
      case value
      when *PRIMITIVES        then value
      when Symbol             then value.to_s
      when Float              then normalize_float(value, path)
      when Hash               then normalize_hash(value, path)
      when Array              then value.each_with_index.map { |v, i| normalize(v, path + ["[#{i}]"]) }
      when Time, Date         then value.iso8601
      else                         normalize_object(value, path)
      end
    end

    def normalize_hash(hash, path)
      hash.each_with_object({}) do |(key, value), out|
        unless key.is_a?(String) || key.is_a?(Symbol) || key.is_a?(Numeric)
          raise ArgumentError, "#{join(path)} has a #{key.class} key (#{key.inspect}); " \
                               "JSON object keys must be strings, symbols or numbers."
        end

        out[key.to_s] = normalize(value, path + [".#{key}"])
      end
    end

    def normalize_float(float, path)
      return float if float.finite?

      raise ArgumentError, "#{join(path)} is #{float}, which JSON cannot represent."
    end

    def normalize_object(value, path)
      if deliberate_as_json?(value)
        normalize(value.as_json, path)
      elsif deliberate_to_h?(value)
        normalize(value.to_h, path)
      else
        raise ArgumentError, <<~MSG.strip
          #{join(path)} is a #{value.class}, which is not JSON-serializable.

          Convert it first — a serializer, a class that defines #as_json, or a plain
          Hash of strings and numbers. Passing it through would put an empty object
          or an inspect string into your document.
        MSG
      end
    end

    # True when the object's class defines as_json itself, rather than picking
    # up ActiveSupport's Object-level fallback.
    def deliberate_as_json?(value)
      return false unless value.respond_to?(:as_json)

      !GENERIC_AS_JSON_OWNERS.include?(value.method(:as_json).owner)
    rescue NameError
      false
    end

    def deliberate_to_h?(value)
      return false unless value.respond_to?(:to_h)

      !GENERIC_AS_JSON_OWNERS.include?(value.method(:to_h).owner)
    rescue NameError
      false
    end

    # ["data", ".line_items", "[0]", ".amount"] => data.line_items[0].amount
    def join(path)
      path.join
    end
  end
end
