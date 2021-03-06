module Invitational
  module CanCan
    module Ability

      def can(action = nil, subject = nil, conditions = nil, &block)
        if conditions && conditions.has_key?(:roles)
          roles = conditions.delete(:roles) if conditions
          conditions = nil if conditions and conditions.empty?

          block ||= setup_role_based_block_for roles, subject, action
        end

        rules << ::CanCan::Rule.new(true, action, subject, conditions, block)
      end

      def setup_role_based_block_for roles, subject, action
        key = subject.name.underscore + action.to_s

        if roles.respond_to? :values
          role_type, roles  = [roles.keys.first, roles.values.first]
        else
          role_type = subject
        end

        role_mappings[key] = roles

        block = ->(model){
          roles = role_mappings[key]
          check_permission_for model, user, roles
        }

        block
      end

      def check_permission_for model, user, in_roles

        in_roles.reduce(false) do |result,role|
          result || if role.respond_to? :values
            method = role.keys.first
            related = model.send(method)

            if related.respond_to? :any?
              related.any? do |model|
                check_permission_for model, user, role.values.flatten
              end
            else
              check_permission_for related, user, role.values.flatten
            end

          else
            Invitational::ChecksForInvitation.for(user, model, role)
          end
        end

      end

      def attribute_roles attribute, roles
        {attribute => roles}
      end

    end
  end
end
