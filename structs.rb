# coding: utf-8

# this file defines a couple data structures
# that I needed.


# First, we have a priority queue, designed
# for maintaining a list of upcoming events
# and withdrawing events as time advances
class TimingQueue
  # implemented as a skew heap
  
  def initialize
    @root = nil
  end

  # add the pair (time,card) to the queue
  def enroll(card,time)
    newnode = SkewNode.new(time,card)
    @root = merge(@root,newnode)
  end

  # pop from the queue until
  # the queue is empty or the head of the queue
  # is later than time.
  # return all the popped items in an array
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

end

# the nodes for the skew heap
class SkewNode
  attr_accessor :left, :right, :priority, :value
  
  def initialize(priority,value)
    @priority = priority
    @value = value
    @left = @right = nil
  end
end

# skew heap merge
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


# Second of all, an abstract set (no duplicates) which
# allows for the following operations in constant time:
# * removing a random element from the collection
# * adding a new element to the collection
# * removing an element from the collection, by value
# * getting the size of the collection
# * checking membership by value
class RandomRemovalSet

  # internally, we store the contents of the collection
  # in an Array, and there's also a Hash which maps values
  # to their indices
  def initialize
    @content = []
    @indices = Hash.new
  end

  # check membership by value
  def include?(x)
    @indices[x] # huh
  end

  # return the size of the set
  def size
    @content.size
  end

  # add to the set
  def add(x)
    unless include?(x)
      @indices[x] = @content.size
      @content.push(x)
    end
  end

  # remove the value x from the set,
  # fail silently
  def remove(x)
    if include?(x)
      ind = @indices[x]
      ind2 = @content.size - 1
      swap(ind,ind2) # do this to ensure constant time
      removeEnd
    end
  end

  # remove a random value from the collection,
  # and return it
  def pullRandom
    return nil if size == 0
    ind = rand(size)
    swap(ind,size-1)
    removeEnd
  end

  private
  # safely swap the internal location of two values,
  # in O(1) time
  def swap(index1,index2)
    if index1==index2
      return
    end
    # swap the entries in the list
    @content[index1],@content[index2] = @content[index2],@content[index1]
    # fix the indices map
    @indices[@content[index1]] = index1
    @indices[@content[index2]] = index2
  end

  # safely remove the end of the list
  def removeEnd
    @indices.delete(@content[-1])
    @content.pop
  end

end

