require 'pp'
require 'json'
require 'open3'
require 'csv'

module Aws
  class Counter
    PHASE_LIST = %w(ci dev prd)
    REGION = 'ap-northeast-1'

    def initialize
      @data = {}
      @cli_history = { cmd: nil, cache: nil }
    end

    def cli(cmd_str, region = REGION)
      @cli_str = cmd_str + " --region #{region}"
      self
    end

    def map(mode = nil, &block)
      case mode
      when :per_phase
        PHASE_LIST.each { |phase| @data[phase] = 0 }
      else
        @data = {}
      end
      @map_logic = block
      self
    end

    def save(file)
      _map(_cli)
      _save(file)
      self
    end

    def execute
      _map(_cli)
      _save
      self
    end

    def _cli
      return @cli_history[:cache] if !@cli_history[:cache].nil? && @cli_history[:cmd] == @cli_str
      @cli_history[:cmd] = @cli_str
      pp @cli_str
      stdout, stderr, status = Open3.capture3(@cli_str)
      if status.exitstatus > 0
        @cli_history[:cache] = nil
        fail stderr
      end
      @cli_history[:cache] = JSON.parse(stdout)
      @cli_history[:cache]
    end

    def _map(obj)
      @map_logic.call(obj, @data)
    end

    def _save(file)
      table = []
      @data.each { |k, v| table << [k, v] }
      CSV.open(file, 'wb') { |csv| table.transpose.each { |arr| csv << arr } }
    end
  end
end
