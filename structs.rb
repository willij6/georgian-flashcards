# coding: utf-8

class SkewNode
  attr_accessor :left, :right, :priority, :value
  
  def initialize(priority,value)
    @priority = priority
    @value = value
    @left = @right = nil
  end
end

def merge(node1,node2)
  if node1
    if node2
      if node1.priority > node2.priority
        node1,node2 = node2,node1
      end
      node1.right = merge(node1.right,node2)
      node1.left,node1.right = node1.right,node1.left
    end
    node1
  else
    node2
  end
end


class TimingQueue
  def initialize
    @root = nil
  end

  def pullFrom(time)
    holding = []
    while @root and @root.priority <= time
      holding.push(@root.value)
      @root = merge(@root.left, @root.right)
    end
    holding
  end

  def empty?
    not @root
  end

  def enroll(card,time)
    newnode = SkewNode.new(time,card)
    @root = merge(@root,newnode)
  end
end

class RandomRemoval
  def initialize
    @content = []
    @indices = Hash.new
  end

  def include?(x)
    @indices[x] # huh
  end

  def size
    @content.size
  end

  def add(x)
    unless include?(x)
      @indices[x] = @content.size
      @content.push(x)
    end
  end

  def remove(x)
    if include?(x)
      ind = @indices[x]
      ind2 = @content.size - 1
      swap(ind,ind2)
      removeEnd
    end
  end

  def pullRandom
    return nil if size == 0
    ind = rand(size)
    swap(ind,size-1)
    removeEnd
  end

  private
  def swap(index1,index2)
    if index1==index2
      return
    end
    @content[index1],@content[index2] = @content[index2],@content[index1]
    @indices[@content[index1]] = index1
    @indices[@content[index2]] = index2
  end

  def removeEnd
    @indices.delete(@content[-1])
    @content.pop
  end

end

