require File.dirname(__FILE__) + '/aws_counter'

SECTION = ''
SERVICE_ID = ''

counter = Aws::Counter.new

counter.cli("aws ec2 describe-instances --filters Name=tag:Name,Values=#{SECTION}-#{SERVICE_ID}-*").map(:per_phase) do |result, data|
  result['Reservations'].collect { |ins| ins['Instances'][0] }.each do |instance|
    if /\w+-\w+-(?<phase>\w+)-.+/ =~ instance['Tags'].find {|tag| tag['Key'].downcase == 'name' }['Value']
      data[phase] += 1
    end
  end
  data['total'] = data.values.inject { |a, e| a + e }
end.save('instance_count_per_phase.csv')

counter.map do |result, data|
  result['Reservations'].collect { |ins| ins['Instances'][0] }.each do |instance|
    type = instance['InstanceType']
    if data[type].nil?
      data[type] = 1
    else
      data[type] += 1
    end
  end
end.save('instance_count_per_type.csv')

counter.map do |result, data|
  types = []
  instances = result['Reservations'].collect { |ins| ins['Instances'][0] }
  instances.each { |instance| types << instance['InstanceType'] }
  types.each do |type|
    Aws::Counter::PHASE_LIST.each { |phase| data["[#{phase}]#{type}"] = 0 }
  end
  instances.each do |instance|
    if /\w+-\w+-(?<phase>\w+)-.+/ =~ instance['Tags'].find {|tag| tag['Key'].downcase == 'name' }['Value']
      data["[#{phase}]#{instance['InstanceType']}"] += 1
    end
  end
end.save('instance_count_per_phase_and_type.csv')
