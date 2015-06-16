require 'lotus/utils/class'

module Lotus
  module Model
    module Config
      # Raised when an adapter class does not exist
      #
      # @since 0.2.0
      class AdapterNotFound < ::StandardError
        def initialize(adapter_name)
          super "Cannot find Lotus::Model adapter #{adapter_name}"
        end
      end

      # Configuration for the adapter
      #
      # Lotus::Model has its own global configuration that can be manipulated
      # via `Lotus::Model.configure`.
      #
      # New adapter configuration can be registered via `Lotus::Model.adapter`.
      #
      # @see Lotus::Model.adapter
      #
      # @example
      #   require 'lotus/model'
      #
      #   Lotus::Model.configure do
      #     adapter type: :sql, uri: 'postgres://localhost/database'
      #   end
      #
      #   Lotus::Model.configuration.adapter_config
      #   # => Lotus::Model::Config::Adapter(type: :sql, uri: 'postgres://localhost/database')
      #
      # By convention, Lotus inflects type to find the adapter class
      # For example, if type is :sql, derived class will be `Lotus::Model::Adapters::SqlAdapter`
      #
      # @since 0.2.0
      class Adapter
        # @return [Symbol] the adapter name
        #
        # @since 0.2.0
        attr_reader :type

        # @return [String] the adapter URI
        #
        # @since 0.2.0
        attr_reader :uri

        # @return [String] the adapter class name
        #
        # @since 0.2.0
        attr_reader :class_name

        # @return [String] the adapter extension
        #
        # @since 0.2.0
        attr_reader :extension

        # Initialize an adapter configuration instance
        #
        # @param options [Hash] configuration options
        # @option options [Symbol] :type adapter type name
        # @option options [String] :uri adapter URI
        #
        # @return [Lotus::Model::Config::Adapter] a new apdapter configuration's
        #   instance
        #
        # @since 0.2.0
        def initialize(**options)
          @type = options[:type]
          @uri  = options[:uri]
          @extension  = options[:extension]
          @class_name ||= Lotus::Utils::String.new("#{@type}_adapter").classify
        end

        # Initialize the adapter
        #
        # @param mapper [Lotus::Model::Mapper] the mapper instance
        #
        # @return [Lotus::Model::Adapters::SqlAdapter, Lotus::Model::Adapters::MemoryAdapter] an adapter instance
        #
        # @see Lotus::Model::Adapters
        #
        # @since 0.2.0
        def build(mapper)
          load_adapter
          instantiate_adapter(mapper)
        end

        private

        def load_adapter
          begin
            require "lotus/model/adapters/#{type}_adapter"
          rescue LoadError => e
            raise LoadError.new("Cannot find Lotus::Model adapter '#{type}' (#{e.message})")
          end
        end

        def instantiate_adapter(mapper)
          begin
            klass = Lotus::Utils::Class.load!(class_name, Lotus::Model::Adapters)
            klass.new(mapper, uri, extension: extension)
          rescue NameError
            raise AdapterNotFound.new(class_name)
          rescue => e
            raise "Cannot instantiate adapter of #{klass} (#{e.message})"
          end
        end

      end
    end
  end
end
