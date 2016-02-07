require File.dirname(__FILE__) + '/aws_counter'

SECTION = ''
SERVICE_ID = ''

counter = Aws::Counter.new
counter.cli("aws ec2 describe-images --filters Name=name,Values=#{SECTION}-#{SERVICE_ID}-*").map(:per_phase) do |result, data|
  data['unknown'] = 0
  result['Images'].each do |image|
    unless image['Tags'].nil?
      phase_tag = image['Tags'].find {|tag| tag['Key'].downcase == 'phase' }
      if phase_tag.nil?
        data['unknown'] += 1
      else
        data[phase_tag['Value'].downcase] += 1
      end
      next
    end
    data['unknown'] += 1
  end
  data['total'] = data.values.inject { |a, e| a + e }
end.save('ami_count.csv')
