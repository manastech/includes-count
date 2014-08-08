require "includes-count/version"

module ActiveRecord
  
  module Associations
    
    class CountPreloader < Preloader
            
      class Count < ActiveRecord::Associations::Preloader::HasOne

        def initialize(klass, owners, reflection, preload_options)
          super
          @preload_options[:select] ||= "#{table.name}.#{association_key_name}, COUNT(id) AS #{count_name}"
        end

        def count_name
          preload_options[:count_name].try(:to_s) || "#{reflection.name}_count"
        end

        def preload
          associated_records_by_owner.each do |owner, associated_records|
            sum = associated_records.map{|r| r[count_name] || 0}.sum
            owner.instance_eval "
              def #{count_name}
                @#{count_name} ||= 0
                @#{count_name} += #{sum}
              end  
            "
          end
        end

        def build_scope
          super.group(association_key)
        end

      end
      
      class CountHasMany < Count
      end
      
      class CountHasManyThrough < Count
        include ThroughAssociation
        
        def associated_records_by_owner          
          through_records = through_records_by_owner

          ActiveRecord::Associations::CountPreloader.new(
            through_records.values.flatten,
            source_reflection.name, options.merge(@preload_options)
          ).run

          through_records
          
        end
         
        def through_records_by_owner
          ActiveRecord::Associations::Preloader.new(
            owners, through_reflection.name,
            through_options
          ).run

          Hash[owners.map do |owner|
            through_records = Array.wrap(owner.send(through_reflection.name))

            # Dont cache the association - we would only be caching a subset
            if reflection.options[:source_type] && through_reflection.collection?
              owner.association(through_reflection.name).reset
            end

            [owner, through_records]
          end]
        end

        def through_options
          through_options = {}

          if options[:source_type]
            through_options[:conditions] = { reflection.foreign_type => options[:source_type] }
          else
            if options[:conditions]
              through_options[:include]    = options[:include] || options[:source]
              through_options[:conditions] = options[:conditions]
            end

            through_options[:order] = options[:order]
          end
          
          if @preload_options[:through_options]
            through_preload_options = @preload_options[:through_options][through_reflection.name.to_sym] || {}
            through_options.merge!(through_preload_options)
          end
        
          through_options
        end
        
      end
      
      def preloader_for(reflection)
        case reflection.macro 
          when :has_many
            reflection.options[:through] ? CountHasManyThrough : CountHasMany
          else
            raise "unsupported association kind #{reflection.macro}"
        end
      end
      
    end
  
  end
  
  class Relation
  
    attr_accessor :includes_counts_values
  
    def includes_count(*args)
      args.reject! {|a| a.blank? }

      return self if args.empty?

      relation = clone
      (relation.includes_counts_values ||= []) << args
      relation
    end
  
    def to_a_with_includes_count
      return @records if loaded?
      
      to_a_without_includes_count
      
      (includes_counts_values || []).each do |association_with_opts|
        association, opts = association_with_opts
        ActiveRecord::Associations::CountPreloader.new(@records, [association], opts).run
      end
      
      @records
    end

    alias_method_chain :to_a, :includes_count

  end
  
end