# frozen_string_literal: true

module OpenapiContractHelpers
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def documented_response(status, description, examples: nil, &definition)
      response status, description do
        class_exec(&definition) if definition
        Array(examples).each do |ex|
          example ex.fetch(:media, "application/json"), ex.fetch(:name, :example), ex.fetch(:value)
        end
        specify("documents the #{status} response") { expect(status).to match(/\A\d{3}\z/) }
      end
    end
  end
end
