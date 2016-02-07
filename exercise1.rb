#!/usr/bin/ruby

require 'contracts'

# Number of fast servers
m = 100
# Number of slow servers
k = 100

# Number of tasks
n = 10000

class Task
  include Contracts::Core

  attr_reader :length, :completion

  def initialize
    @length = rand(1000)
    @completion = 0
  end

  Contract Contracts::None => Contracts::Any
  def iterate
    @completion += 1
  end

  Contract Contracts::None => Contracts::Bool
  def done?
    @length <= @completion
  end
end

class Server
  include Contracts::Core

  attr_reader :tasks, :speed, :tasks_completed

  def initialize(speed_factor)
    @speed = speed_factor
    @tasks = []
    @tasks_completed = 0
  end

  Contract Task => Contracts::Any
  def <<(task)
    @tasks << task
  end

  Contract Contracts::None => Contracts::Bool
  def free?
    @tasks.size == 0
  end

  Contract Contracts::None => Contracts::Any
  def iterate
    @speed.times do
      return if @tasks.empty?
      current_task = @tasks.first
      if current_task.done?
        @tasks.shift
        @tasks_completed += 1
        next
      end
      current_task.iterate
    end
  end
end

# Let's create 1000 tasks [0; 999]
tasks = (0...n).to_a.map { Task.new }

# Now, let's do this greedily.
servers = []

m.times { servers << Server.new(3) }
k.times { servers << Server.new(1) }

greedy_iterations = 0

# In the beginning, each server has a task to process
loop do
  servers_indexes = servers.size.times.to_a.shuffle # Servers are selected at random

  # Each server is iterated once
  servers_indexes.each do |i|
    servers[i] << tasks.shift if servers[i].free? and tasks.size > 0
    servers[i].iterate
  end

  print "."
  greedy_iterations += 1

  break if servers.reduce(m+k) { |memo, e| memo - (e.free? ? 1 : 0) } == 0
end

greedy_avg_fast = m.times.to_a.map{ |i| servers[i].tasks_completed }.reduce(&:+) / m.to_f
greedy_avg_slow = k.times.to_a.map{ |i| servers[m+i].tasks_completed }.reduce(&:+) / k.to_f

puts

# Let's create 1000 tasks [0; 999]
tasks = (0...n).to_a.map { Task.new }

# Now, let's do this greedily.
servers = []

m.times { servers << Server.new(3) }
k.times { servers << Server.new(1) }

improved_greedy_iterations = 0

# In the beginning, each server has a task to process
loop do
  # Each server is iterated once
  servers.each do |server|
    server.speed.times { server << tasks.shift if tasks.size > 0 }
    server.iterate
  end

  print "."
  improved_greedy_iterations += 1

  break if servers.reduce(m+k) { |memo, e| memo - (e.free? ? 1 : 0) } == 0
end

improved_greedy_avg_fast = m.times.to_a.map{ |i| servers[i].tasks_completed }.reduce(&:+) / m.to_f
improved_greedy_avg_slow = k.times.to_a.map{ |i| servers[m+i].tasks_completed }.reduce(&:+) / k.to_f

puts
puts
puts "Considering #{n} tasks on #{m} fast servers and #{k} slow servers."
puts
puts "Greedy algorithm, #{greedy_iterations} iterations:"
puts "  Average number of tasks completed on fast servers: #{greedy_avg_fast}."
puts "  Average number of tasks completed on slow servers: #{greedy_avg_slow}."
puts
puts "Improved greedy algorithm, #{improved_greedy_iterations} iterations:"
puts "  Average number of tasks completed on fast servers: #{improved_greedy_avg_fast}."
puts "  Average number of tasks completed on slow servers: #{improved_greedy_avg_slow}."
