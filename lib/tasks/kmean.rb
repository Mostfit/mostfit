#This is used in auto_simulation.rake for clustering of locations

def kmeans(data, k, delta=10.0)
  clusters = []

  # Assign intial values for all clusters
  (1..k).each do |point|
    index = (data.length * rand).to_i

    rand_point = data[index]
    c = Cluster.new(rand_point)

    clusters.push c
  end

  # Loop
  while true
    # Assign points to clusters
    data.each do |point|
      min_dist = 1.0/0
      min_cluster = nil

      # Find the closest cluster
      clusters.each do |cluster|
        dist = point.dist_to(cluster.center)

        if dist < min_dist
          min_dist = dist
          min_cluster = cluster
        end
      end

      # Add to closest cluster
      min_cluster.points.push point
    end

    # Check deltas
    max_delta = -100000000

    clusters.each do |cluster|
      next if cluster.points.length == 0
      dist_moved = cluster.recenter!

      # Get largest delta
      if dist_moved > max_delta
        max_delta = dist_moved
      end
    end

    # Check exit condition
    if max_delta < delta
      return clusters
    end

    # Reset points for the next iteration
    clusters.each do |cluster|
      cluster.points = []
    end
  end
end
