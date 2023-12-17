"""
    SetPartition

`SetPartition` represents a partition of a set of upper and lower points 
into disjoint subsets. 
Such set-partitions are often depicted as string diagrams where points in the same subset 
are connected by lines. See also Section 4.1.1 in [Gro20](@cite).
"""
struct SetPartition <: AbstractPartition
    upper_points::Vector{Int}
    lower_points::Vector{Int}

    function SetPartition(upper_points::Vector{Int}, lower_points::Vector{Int})
        (new_upper, new_lower) = _normal_form(upper_points, lower_points)
        return new(new_upper, new_lower)
    end
end

"""
    set_partition(upper_points::Vector, lower_points::Vector)

Construct a `SetPartition` with points `upper_points` and `lower_points`
where two points are in the same subset if and only if they have the same value.

Note that `upper_points` and `lower_points` are stored in normal form.

# Examples
```jldoctest
julia> set_partition([2, 4], [4, 99])
SetPartition([1, 2], [2, 3])
```
"""
function set_partition(upper_points::Vector, lower_points::Vector)
    return SetPartition(convert(Vector{Int}, upper_points), 
                        convert(Vector{Int}, lower_points))
end


function hash(p::SetPartition, h::UInt)
    return hash(p.upper_points, hash(p.lower_points, h))
end

function ==(p::SetPartition, q::SetPartition)
    return p.lower_points == q.lower_points && p.upper_points == q.upper_points
end

function deepcopy_internal(p::SetPartition, stackdict::IdDict)
    if haskey(stackdict, p)
        return stackdict[p]
    end
    q = SetPartition(deepcopy_internal(p.upper_points, stackdict), 
                     deepcopy_internal(p.lower_points, stackdict))
    stackdict[p] = q
    return q
end

"""
    upper_points(p::SetPartition)

Return the upper points of `p`.

# Examples
```jldoctest
julia> upper_points(set_partition([2, 4], [4, 99]))
[1, 2]
```
"""
function upper_points(p::SetPartition)
    return p.upper_points
end

"""
    lower_points(p::SetPartition)

Return the lower points of `p`.

# Examples
```jldoctest
julia> lower_points(set_partition([2, 4], [4, 99]))
[2, 3]
"""
function lower_points(p::SetPartition)
    return p.lower_points
end

"""
    tensor_product(p::SetPartition, q::SetPartition)

Return tensor product of `p` and `q`.

The tensor product of two partitions is given by their horizontal concatenation.
See also Section 4.1.1 in [Gro20](@cite).

# Examples
```jldoctest
julia> tensor_product(set_partition([1, 2], [2, 1]), set_partition([1, 1], [1]))
SetPartition([1, 2, 3, 3], [2, 1, 3])
```
"""
function tensor_product(p::SetPartition, q::SetPartition)
    q_new = _new_point_values(upper_points(p), lower_points(p), 
                              upper_points(q), lower_points(q))

    return set_partition(vcat(upper_points(p), q_new[1]), 
                         vcat(lower_points(p), q_new[2]))
end

"""
    involution(p::SetPartition)

Return involution of `p`.

The involution of a partition is obtained by swapping the upper and lower points.
See also Section 4.1.1 in [Gro20](@cite).

# Examples
```jldoctest
julia> involution(set_partition([1, 2, 3], [2, 1]))
SetPartition([1, 2], [2, 1, 3])
```
"""
function involution(p::SetPartition)
    return set_partition(lower_points(p), upper_points(p))
end

"""
    reflect_vertical(p::SetPartition)

Reflect `p` at the vertical axis.

The vertical reflection of a partition is obtained by reversing the order of 
the upper and lower points. See also Section 4.1.2 in [Gro20](@cite).

# Examples
```jldoctest
julia> reflect_vertical(set_partition([1, 2, 3], [2, 1]))
SetPartition([1, 2, 3], [3, 2])
```
"""
function reflect_vertical(p::SetPartition)
    return set_partition(reverse(upper_points(p)), reverse(lower_points(p)))
end

"""
    rotate(p::SetPartition, lr::Bool, tb::Bool)

Rotate `p` in the direction given by `lr` and `tb`. 

Rotating a partition moves the left- or right-most point of the upper points 
to the lower points or vice verca. See also Section 4.1.2 in [Gro20](@cite).

# Arguments
- `p`: input partition
- `lr`: rotating at the left (true) or at the right (false)
- `tb`: rotating from top to bottom (true) or from bottom to top (false)

# Examples
```jldoctest
julia> rotate(set_partition([1, 2, 3], [2, 1]), true, true)
SetPartition([1, 2], [3, 1, 3])

julia> rotate(set_partition([1, 2, 3], [2, 1]), true, false)
SetPartition([1, 2, 1, 3], [2])

julia> rotate(set_partition([1, 2, 3], [2, 1]), false, true)
SetPartition([1, 2], [2, 1, 3])

julia> rotate(set_partition([1, 2, 3], [2, 1]), false, false)
SetPartition([1, 2, 3, 1], [2])
```
"""
function rotate(p::SetPartition, lr::Bool, tb::Bool)
    
    if tb
        @req !isempty(upper_points(p)) "SetPartition has no top part"
    elseif !tb
        @req !isempty(lower_points(p)) "SetPartition has no bottom part"
    end

    ret = (deepcopy(upper_points(p)), deepcopy(lower_points(p)))

    if lr
        if tb
            a = ret[1][1]
            splice!(ret[1], 1)
            pushfirst!(ret[2], a)
        else
            a = ret[2][1]
            splice!(ret[2], 1)
            pushfirst!(ret[1], a)
        end
    else
        if tb
            a = ret[1][end]
            pop!(ret[1])
            push!(ret[2], a)
        else
            a = ret[2][end]
            pop!(ret[2])
            push!(ret[1], a)
        end
    end
    
    return set_partition(ret[1], ret[2])
end


"""
    is_composable(p::SetPartition, q::SetPartition)

Return whether `p` and `q` are composable, i.e. the number of upper points of 
`p` equals the number of lower points of `q`.

# Examples
```jldoctest
julia> is_composable(set_partition([1, 2], [2, 1]), set_partition([1], [1, 1]))
true

julia> is_composable(set_partition([1], [1, 1]), set_partition([1, 2], [2, 1]))
false
```
"""
function is_composable(p::SetPartition, q::SetPartition)
    return num_upper_points(p) == num_lower_points(q)
end

"""
    compose_count_loops(p::SetPartition, q::SetPartition)

Return the composition of `p` and `q` as well as the number of removed loops.

The composition of two partitions is obtained by concatenating them vertically
and removing intermediate loops which are no longer connected to the top or bottom.
See also Section 4.1.1 in [Gro20](@cite).

The composition of `p` and `q` is only defined if the number of upper points of 
`p` equals the number of lower points of `q`. See also [`is_composable`](@ref).

# Examples
```jldoctest
julia> compose_count_loops(set_partition([1, 2], [2, 1]), set_partition([1], [1, 1]))
(SetPartition([1], [1, 1]), 0)

julia> compose_count_loops(set_partition([1, 1], [2]), set_partition([1], [2, 2]))
(SetPartition([1], [2]), 1)

julia> compose_count_loops(set_partition([1], [1, 2]), set_partition([1], [2, 2]))
ERROR: ArgumentError: Number of points mismatch
```
"""
function compose_count_loops(p::SetPartition, q::SetPartition)
    
    @req is_composable(p, q) "Number of points mismatch" 

    # Work with copies to not change the input partitions
    p_copy = deepcopy(p)

    # new_ids dictionary stores the new value we need to assign to the partition,
    # in order to connect new segments
    vector_q = _new_point_values(upper_points(p_copy), lower_points(p_copy), 
                deepcopy(upper_points(q)), deepcopy(lower_points(q)))
    new_ids = Dict{Int, Int}()
    
    # mapping the second the lower points of the second partition 
    # to the upper points of the first partition and merge if connection
    for (i, n) in enumerate(vector_q[2])
        if !(n in keys(new_ids))
            new_ids[n] = upper_points(p)[i]
        else
            if upper_points(p)[i] in keys(new_ids) && new_ids[n] in keys(new_ids)
                # Do path compression if we have the case that we need to merge two tree's 
                # together and the nodes we operate on are not a root or a leaf
                for ii in [n]
                    path = [ii]
                    z = new_ids[ii]
                    already_in = Set(z)
                    while z in keys(new_ids)
                        push!(path, z)
                        push!(already_in, z)
                        z = new_ids[z]
                        z in already_in && break
                    end
                    push!(path, z)
                    for nn in path[1:end-1]
                        new_ids[nn] = path[end]
                    end
                end
                new_ids[new_ids[n]] = new_ids[upper_points(p_copy)[i]]
            else
                if !(new_ids[n] in keys(new_ids))
                    new_ids[new_ids[n]] = upper_points(p_copy)[i]
                else
                    new_ids[upper_points(p_copy)[i]] = new_ids[n]
                end
            end
        end
    end
    
    # final path compression
    for (ii, z) in new_ids
        path = [ii]
        already_in = Set(z)
        while z in keys(new_ids)
            push!(path, z)
            push!(already_in, z)
            z = new_ids[z]
            z in already_in && break
        end
        push!(path, z)
        for nn in path[1:end-1]
            new_ids[nn] = path[end]
        end
    end
    
    # giving the top part new values
    for (i, n) in enumerate(vector_q[1])
        if n in keys(new_ids)
            vector_q[1][i] = new_ids[n]
        end
    end

    # giving the top part new values
    for (i, n) in enumerate(lower_points(p_copy))
        if n in keys(new_ids)
            lower_points(p_copy)[i] = new_ids[n]
        end
    end

    # removing the middle by just changing the top of our partition 
    # to the adjusted top of the second partition
    ret = set_partition(vector_q[1], lower_points(p_copy))

    # calculating removed related components (loop)
        
    related_comp = Set()
    return_partition_as_set = Set(vcat(vector_q[1], lower_points(p_copy)))

    # calculate new ids for middle nodes, which are under normal circumstances omitted
    for (i, n) in enumerate(vector_q[2])
        if n in keys(new_ids)
            vector_q[2][i] = new_ids[n]
        end
    end

    for (i, n) in enumerate(upper_points(p_copy))
        if n in keys(new_ids)
            upper_points(p_copy)[i] = new_ids[n]
        end
    end

    for co in vcat(vector_q[2], upper_points(p_copy))
        if !(co in return_partition_as_set)
            push!(related_comp, co)
        end
    end
    
    return (ret, length(related_comp))
end
