#This class is made for the application of k-mean clustering algorithm used in auto_simulation.rake

class Point
  attr_accessor :name, :lat, :long

  # Constructor that takes in an x,y coordinate
  def initialize(name, lat, long)
    @name = name
    @lat = lat#[0..1].to_i + lat[3..4].to_i/60.0
    @long = long#[0..1].to_i + long[3..4].to_i/60.0
  end

  # Calculates the distance to Point p
  def dist_to(p)
    dlat = (@lat - p.lat) * Math::PI / 180
    dlon = (@long - p.long) * Math::PI / 180
    a    = Math.sin(dlat/2) * Math.sin(dlat/2) + Math.cos(@lat * Math::PI/180) * Math.cos(p.lat * Math::PI / 180) * Math.sin(dlon/2) * Math.sin(dlon/2)
    c    = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    return 6371.009 * c
  end

  # Return a String representation of the object
  def to_s
    return "#{@name} - (#{@lat}, #{@long})"
  end
end

#point = Point.new("Balliapal", "26*40`N", "87*17`E")
#puts point.dist_to(Point.new("Ballia", "25*46`N", "84*12`E"))
