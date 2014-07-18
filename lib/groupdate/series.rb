module Groupdate
  class Series
    attr_accessor :magic, :relation

    def initialize(magic, relation)
      @magic = magic
      @relation = relation
    end

    def cumulative_sum
      magic.options[:carry_forward] = true
      sql =
        if magic.send(:postgresql?)
          "SUM(COUNT(id)) OVER (ORDER BY #{relation.group_values[0]})::integer"
        else
          raise NoMethodError, "method `cumulative_sum' not supported for MySQL"
        end

      custom(sql)
    end

    # clone to prevent modifying original variables
    def method_missing(method, *args, &block)
      # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/calculations.rb
      if ActiveRecord::Calculations.method_defined?(method) || method == :custom
        magic.perform(relation, method, *args, &block)
      elsif @relation.respond_to?(method)
        Groupdate::Series.new(magic, relation.send(method, *args, &block))
      else
        super
      end
    end

    def respond_to?(method, include_all = false)
      ActiveRecord::Calculations.method_defined?(method) || relation.respond_to?(method) || super
    end

  end
end
