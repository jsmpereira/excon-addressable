# frozen_string_literal: true

require 'addressable/template'
require 'addressable/uri'
require 'excon'
require 'excon/addressable/parser'
require 'excon/addressable/version'

Excon.defaults[:uri_parser] = Excon::Addressable::Parser

# Excon
#
# We inject the `expand` key to the allowed lists of keys to be used when
# creating a request, or connection object. Excon does not enforce this yet, but
# it does print a warning, so this makes things future-proof.
module Excon
  module Addressable
    # Middleware
    #
    # Parses a Templated URI string and merges it with the provided variables.
    #
    class Middleware < Excon::Middleware::Base
      def self.valid_parameter_keys
        [:expand]
      end
      
      def request_call(datum)
        # we need to convert a query hash (or string) to the proper format for
        # Addressable to work with. We also need to remove the `?` character
        # that Excon prepends to the final query string.
        datum[:query] = Excon::Utils.query_string(datum)[1..-1]

        url = ::Addressable::URI.new(datum)

        if (template = ::Addressable::Template.new(url)) && template.variables.any?
          uri = template.expand(datum[:expand].to_h)
          datum.merge!(uri.to_hash)
        end

        super
      end
    end
  end
end
