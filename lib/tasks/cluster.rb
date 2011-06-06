#This class is made for the application of k-mean clustering algorithm used in auto_simulation.rake

class Cluster
  attr_accessor :center, :points

  # Constructor with a starting centerpoint
  def initialize(center)
    @center = center
    @points = []
  end

  # Recenters the centroid point and removes all of the associated points
  def recenter!
    lata = longa = 0
    old_center = @center

    # Sum up all x/y coords
    @points.each do |point|
      lata += point.lat
      longa += point.long
    end

    # Average out data
    lata /= @points.length
    longa /= @points.length

    # Reset center and return distance moved
    @center = Point.new("center", lata, longa)
    return old_center.dist_to(center)    
  end

  def centerize
    min_dist = 1.0/0
    new_cent = nil
    @points.each{|point|
      dist = @center.dist_to(point)
      if dist < min_dist
        new_cent = point 
        min_dist = dist
      end
    }
    @center = new_cent if new_cent
    @points = @points - [@center]
  end
end
