require File.dirname(__FILE__) + '/aws_counter'

SECTION = ''
SERVICE_ID = ''

module STACK_SHORT_STATUS
  IN_PROGRESS = 'IN_PROGRESS'
  FAILED = 'FAILED'
  COMPLETE = 'COMPLETE'
  ROLLBACK = 'ROLLBACK'
end

STACK_STATUS = {
  'CREATE_IN_PROGRESS' => STACK_SHORT_STATUS::IN_PROGRESS,
  'CREATE_FAILED' => STACK_SHORT_STATUS::FAILED,
  'CREATE_COMPLETE' => STACK_SHORT_STATUS::COMPLETE,
  'ROLLBACK_IN_PROGRESS' => STACK_SHORT_STATUS::IN_PROGRESS,
  'ROLLBACK_FAILED' => STACK_SHORT_STATUS::FAILED,
  'ROLLBACK_COMPLETE' => STACK_SHORT_STATUS::ROLLBACK,
  'DELETE_IN_PROGRESS' => STACK_SHORT_STATUS::IN_PROGRESS,
  'DELETE_FAILED' => STACK_SHORT_STATUS::FAILED,
  # 'DELETE_COMPLETE' => STACK_SHORT_STATUS::DELETE,
  'UPDATE_IN_PROGRESS' => STACK_SHORT_STATUS::IN_PROGRESS,
  'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS' => STACK_SHORT_STATUS::IN_PROGRESS,
  'UPDATE_COMPLETE' => STACK_SHORT_STATUS::COMPLETE,
  'UPDATE_ROLLBACK_IN_PROGRESS' => STACK_SHORT_STATUS::IN_PROGRESS,
  'UPDATE_ROLLBACK_FAILED' => STACK_SHORT_STATUS::FAILED,
  'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS' => STACK_SHORT_STATUS::IN_PROGRESS,
  'UPDATE_ROLLBACK_COMPLETE' => STACK_SHORT_STATUS::COMPLETE }

counter = Aws::Counter.new
counter.cli("aws cloudformation list-stacks --stack-status-filter #{STACK_STATUS.keys.join(' ')}").map(:per_phase) do |result, data|
  result['StackSummaries'].each do |stack|
    if /\w+-\w+-(?<phase>\w+)-.+/ =~ stack['StackName']
      data[phase] += 1
    end
  end
  data['total'] = data.values.inject { |a, e| a + e }
end.save('stack_count.csv')

counter.map do |result, data|
  STACK_STATUS.keys.each { |status| data[status] = 0 }
  result['StackSummaries'].each do |stack|
    if /\w+-\w+-(?<phase>\w+)-.+/ =~ stack['StackName']
      if STACK_STATUS.keys.include?(stack['StackStatus'])
        data[stack['StackStatus']] += 1
      else
        data['UNKNOWN'] += 1
      end
    end
  end
end.save('stack_count_per_status.csv')

counter.map do |result, data|
  STACK_STATUS.values.each do |status|
    Aws::Counter::PHASE_LIST.each { |phase| data["[#{phase}]#{status}"] = 0 }
  end
  result['StackSummaries'].each do |stack|
    if /\w+-\w+-(?<phase>\w+)-.+/ =~ stack['StackName']
      if STACK_STATUS.keys.include?(stack['StackStatus'])
        data["[#{phase}]#{STACK_STATUS[stack['StackStatus']]}"] += 1
      else
        data["[#{phase}]UNKNOWN"] += 1
      end
    end
  end
end.save('stack_count_per_phase_and_status.csv')
