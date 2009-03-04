class ChartsTimelineController < ChartsController

  unloadable
  
  protected

  def get_data(conditions, grouping , range)
    prepare_ranged = RedmineCharts::RangeUtils.prepare_range(range, "spent_on")

    conditions[:spent_on] = (prepare_ranged[:date_from])...(prepare_ranged[:date_to])

    group = []
    group << prepare_ranged[:sql]
    group << "user_id" if grouping == :users
    group << "issue_id" if grouping == :issues
    group << "project_id" if grouping == :projects
    group << "activity_id" if grouping == :activities
    group << "issues.category_id" if grouping == :categories
    group = group.join(", ")

    select = []
    select << "#{prepare_ranged[:sql]} as value_x"
    select << "count(1) as count_y"
    select << "sum(hours) as value_y"
    select << "user_id as group_id" if grouping == :users
    select << "issue_id as group_id" if grouping == :issues
    select << "project_id as group_id" if grouping == :projects
    select << "activity_id as group_id" if grouping == :activities
    select << "issues.category_id as group_id" if grouping == :categories
    select << "0 as group_id" if grouping.nil? or grouping == :none
    select = select.join(", ")

    rows = TimeEntry.find(:all, :joins => "left join issues on issues.id = issue_id", :select => select, :conditions => conditions, :order => "1", :readonly => true, :group => group)

    sets = {}
    max = 0

    if rows.size > 0
      rows.each do |row|
        group_name = RedmineCharts::GroupingUtils.to_string(row.group_id, grouping)
        index = prepare_ranged[:keys].index(row.value_x)
        if index
          sets[group_name] ||= Array.new(prepare_ranged[:steps], [0, get_hints])
          sets[group_name][index] = [row.value_y.to_i, get_hints(row, grouping)]
          max = row.value_y.to_i if max < row.value_y.to_i
        else
          raise row.value_x.to_s
        end
      end
    else
      sets[""] ||= Array.new(prepare_ranged[:steps], [0, get_hints])
    end

    sets = sets.collect { |name, values| [name, values] }

    {
      :labels => prepare_ranged[:labels],
      :count => prepare_ranged[:steps],
      :max => max,
      :sets => sets
    }
  end

  def get_hints(record = nil, grouping = nil)
    unless record.nil?
      l(:charts_timeline_hint, { :hours => record.value_y.to_i, :entries => record.count_y.to_i })
    else
      l(:charts_timeline_hint_empty)
    end
  end

  def get_title
    l(:charts_link_timeline)
  end
  
  def get_help
    l(:charts_timeline_help)
  end
  
  def get_type
    :line
  end
  
  def get_x_legend
    l(:charts_timeline_x)
  end
  
  def get_y_legend
    l(:charts_timeline_y)
  end
  
  def show_x_axis
    true
  end
  
  def show_y_axis
    true
  end
  
  def show_date_condition
    true
  end
  
  def get_grouping_options
    [ :none, :users, :issues, :activities, :categories ]
  end
  
end
