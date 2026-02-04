# frozen_string_literal: true

# Placeholder serializer for Ottiv Analytics Metrics
# TODO: Implement metrics serialization
module Analytics
module Serializers
  class MetricsSerializer
    def initialize(metrics)
      @metrics = metrics
    end

    def to_json
      # TODO: Implement metrics serialization
      @metrics.to_json
    end
  end
end
end

end
