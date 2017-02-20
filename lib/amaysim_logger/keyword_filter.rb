class AmaysimLogger
  class KeywordFilter
    MASK = '[MASKED]'.freeze

    class << self
      def filter(content, filtered_keywords)
        return content unless filtered_keywords.any?
        content = filter_hash(content, filtered_keywords) if content.respond_to?(:keys)
        content = filter_json(content, filtered_keywords)
        content = filter_xml(content, filtered_keywords)
        content
      end

      private

      # rubocop:disable Metrics/MethodLength
      def filter_hash(content, filtered_keywords)
        result = content.clone
        result.each do |key, val|
          if to_lower_case(filtered_keywords).include?(key.to_s.downcase)
            result[key] = MASK
          elsif val.is_a?(Hash)
            result[key] = filter_hash(val, filtered_keywords)
          elsif val.is_a?(String) || val.is_a?(Symbol)
            result[key] = filter_xml(val.to_s, filtered_keywords)
          end
        end
        result
      end

      def filter_json(content, filtered_keywords)
        return content unless content.is_a?(String)
        json = JSON.parse(content)
        filter_hash(json, filtered_keywords).to_json
      rescue
        content
      end

      def filter_xml(content, filtered_keywords)
        return content unless content.is_a?(String)
        result = content
        to_lower_case(filtered_keywords).each do |keyword|
          regex = %r{<#{keyword}>\s*(.+?)\s*</#{keyword}>}i
          if regex.match(result)
            result = result.gsub(regex, "<#{keyword}>#{MASK}</#{keyword}>")
          end
        end
        result
      end

      def to_lower_case(filtered_keywords)
        filtered_keywords.map(&:to_s).map(&:downcase)
      end
    end
  end
end
