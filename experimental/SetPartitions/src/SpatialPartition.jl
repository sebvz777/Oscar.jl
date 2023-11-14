"""
    SpatialPartition

Initialize SpatialPartition object
"""
struct SpatialPartition <: AbstractPartition
    partition::SetPartition
    dimension::Int
end

function spatial_partition(partition::SetPartition, dim::Int)

    return SpatialPartition(partition, dim)

end

function hash(p::SpatialPartition, h::UInt)

    hash(p.partition, hash(p.dimension, h))
    
end

function ==(p::SpatialPartition, q::SpatialPartition)

    p.partition == q.partition && p.dimension == q.dimension

end

function copy(p::SpatialPartition)
    return SpatialPartition(copy(p.partition), copy(p.dimension))
end

"""
    tensor_product(p::SpatialPartition, q::SpatialPartition)

Apply tensor product of `p` and `q` and return result.
"""
function tensor_product(p::SpatialPartition, q::SpatialPartition)

    p.dimension != q.dimension ? 
        error("p and q have different dimensions in tensor product") : 

    SpatialPartition(tensor_product(p.partition, q.partition), p.dimension)
end

"""
    involution(p::SpatialPartition)

Apply and return involution of `p` and return result.
"""
function involution(p::SpatialPartition)

    SpatialPartition(involution(p.partition), p.dimension)

end

"""
    composition_loops(p::SpatialPartition, q::SpatialPartition)

Apply composition between `p` and `q` and return tuple including the result
as well as the number of removed loops.
"""
function composition_loops(p::SpatialPartition, q::SpatialPartition)

    !is_composable(p, q) ? error("p and q have different dimensions in composition") : 

    comp_loops = composition_loops(p.partition, q.partition)

    (SpatialPartition(comp_loops[1], p.dimension), comp_loops[2])

end
