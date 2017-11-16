module Fastlane
  module Actions
    module SharedValues
      MATCH_PROVISIONING_PROFILE_MAPPING = :MATCH_PROVISIONING_PROFILE_MAPPING
    end

    class SynchronizeProvisioningAction < Action
      def self.run(params)
        require 'match'

        params.load_configuration_file("Matchfile")
        Match::Runner.new.run(params)

        define_profile_type(params)
        define_provisioning_profile_mapping(params)
      end

      def self.define_profile_type(params)
        profile_type = "app-store"
        profile_type = "ad-hoc" if params[:type] == 'adhoc'
        profile_type = "development" if params[:type] == 'development'
        profile_type = "enterprise" if params[:type] == 'enterprise'

        UI.message("Setting Provisioning Profile type to '#{profile_type}'")

        Actions.lane_context[SharedValues::SIGH_PROFILE_TYPE] = profile_type
      end

      # Maps the bundle identifier to the appropriate provisioning profile
      # This is used in the _gym_ action as part of the export options
      # e.g.
      #
      #   export_options: {
      #     provisioningProfiles: { "me.themoji.app.beta": "match AppStore me.themoji.app.beta" }
      #   }
      #
      def self.define_provisioning_profile_mapping(params)
        mapping = Actions.lane_context[SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING] || {}

        # Array (...) to make sure it's an Array, Ruby is magic, try this
        #   Array(1)      # => [1]
        #   Array([1, 2]) # => [1, 2]
        Array(params[:app_identifier]).each do |app_identifier|
          env_variable_name = Match::Utils.environment_variable_name_profile_name(app_identifier: app_identifier,
                                                                                            type: Match.profile_type_sym(params[:type]),
                                                                                        platform: params[:platform])
          mapping[app_identifier] = ENV[env_variable_name]
        end

        Actions.lane_context[SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING] = mapping
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Easily sync your certificates and profiles across your team (via `match`)"
      end

      def self.details
        "More details https://github.com/fastlane/fastlane/tree/master/match"
      end

      def self.available_options
        require 'match'
        Match::Options.available_options
      end

      def self.output
        []
      end

      def self.return_value
      end

      def self.authors
        ["KrauseFx"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end

      def self.example_code
        [
          'synchronize_provisioning(type: "appstore", app_identifier: "tools.fastlane.app")',
          'synchronize_provisioning(type: "development", readonly: true)',
          'synchronize_provisioning(app_identifier: ["tools.fastlane.app", "tools.fastlane.sleepy"])'
        ]
      end

      def self.category
        :code_signing
      end
    end
  end
end
