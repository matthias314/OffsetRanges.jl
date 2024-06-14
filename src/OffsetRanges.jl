module OffsetRanges

export OffsetStepRange, OffsetUnitRange, offsetarray, from1, Origin

using Base: OneTo, Fix1
import Base: show, axes, step, length, step, first, last, getindex, isempty, values, similar

const TupleVararg1{T} = Tuple{T, Vararg{T}}

argerror(s...) = throw(ArgumentError(s...))

# OffsetStepRange, OffsetUnitRange, OffsetRange

struct OffsetStepRange{T,S,P<:AbstractUnitRange{Int},Q<:OrdinalRange{T,S}} <: OrdinalRange{T,S}
    inds::P
    vals::Q
end

function OffsetStepRange(inds::AbstractUnitRange{<:Integer}, start, step)
    stop = start+step*(length(inds)-1)
    OffsetStepRange(inds, start:step:stop)
end

struct OffsetUnitRange{T,P<:AbstractUnitRange{Int},Q<:AbstractUnitRange{T}} <: AbstractUnitRange{T}
    inds::P
    vals::Q
end

function OffsetUnitRange(inds::AbstractUnitRange{<:Integer}, start::Integer)
    stop = start+(length(inds)-1)
    OffsetUnitRange(inds, start:stop)
end

OffsetUnitRange(inds::AbstractUnitRange{<:Integer}) = OffsetUnitRange(inds, OneTo(length(inds)))

const OffsetRange{T} = Union{OffsetStepRange{T},OffsetUnitRange{T}}

(::Type{O})(start::Integer, r::OrdinalRange) where O <: OffsetRange = O(start:start+length(r)-1, r)

show(io::IO, r::OffsetRange) = print(io, r.inds => values(r))

axes(r::OffsetRange) = (first(r.inds):last(r.inds),)

values(r::OffsetRange) = r.vals

step(r::OffsetStepRange) = step(values(r))

first(r::OffsetRange) = first(values(r))

last(r::OffsetRange) = last(values(r))

# import Base: firstindex, lastindex, size
# firstindex(r::OffsetRange) = first(axes(r, 1))
# lastindex(r::OffsetRange) = last(axes(r, 1))
# size(r::OffsetRange) = (length(r),)

length(r::OffsetRange) = length(axes(r, 1))

isempty(r::OffsetRange) = isempty(r.inds)

@inline function getindex(r::OffsetRange, i::Integer)
    @boundscheck checkbounds(r, i)
    first(r)+step(r)*(i-firstindex(r))
end

@inline function getindex(r::OrdinalRange, s::OffsetRange{<:Integer})
    @boundscheck checkbounds(r, s)
    @inbounds OffsetStepRange(axes(s, 1), r[first(s)], step(r)*step(s))
end

# @inline function getindex(r::AbstractUnitRange, s::AbstractUnitRange{<:Integer})
# TODO: for AbstractUnitRange this is already defined in range.jl
@inline function getindex(r::AbstractUnitRange, s::OffsetUnitRange{<:Integer})
    @boundscheck checkbounds(r, s)
    @inbounds OffsetUnitRange(axes(s, 1), r[first(s)])
end

# Origin

struct Origin{N}
    t::NTuple{N,Int}
end

Origin(ii::Integer...) = Origin(ii)
Origin(ci::CartesianIndex) = Origin(Tuple(ci))
Origin(a::AbstractArray) = Origin(map(first, axes(a)))

# Base.:(-)(o::Origin) = Origin(map(-, o.t))

(o::Origin)(a::AbstractArray) = OffsetArray(a, o)

# OffsetArray

function unsafe_fast_subarray(a::SubArray{T,N,P,I}) where {T,N,P,I}
# force fast linear indexing if supported by parent
    if IndexStyle(parent(a)) isa IndexLinear
        fs = ntuple(Fix1(getfield, a), fieldcount(SubArray))
        SubArray{T,N,P,I,true}(fs...)
    else
        a
    end
end

unsafe_fast_subarray(a::AbstractArray) = a

function oa_range(r, s::AbstractUnitRange{<:Integer})
    length(r) == length(s) || argerror("existing axis $r and new range $s have different lengths")
    # r isa OneTo && s isa OneTo ? Colon() : OffsetUnitRange(s, r)
    OffsetUnitRange(s, r)
end

oa_range(r, n::Integer) = OffsetUnitRange(first(r)+n:last(r)+n, r)
oa_range(r, ::Colon) = Colon()
oa_range(r, ::T) where T = argerror("$T not supported to specify an axis")

decart(t) = t
decart(t, x, xs...) = decart((t..., x), xs...)
decart(t, x::CartesianIndices, xs...) = decart((t..., x.indices...), xs...)  # TODO: without "indices"?

function offsetarray(a::AbstractArray{T,N}, rs...) where {T,N}
    rsd = decart((), rs...)
    length(rsd) == N || argerror("array has dimension $N, but received $rs as new axes")
    unsafe_fast_subarray(view(a, map(oa_range, axes(a), rsd)...))
end

function offsetarray(a::AbstractArray{T,N}, o::Origin) where {T,N}
    t = o.t == (0,) ? ntuple(Returns(0), N) : o.t
    length(t) == N || argerror("array has dimension $N, but received $o as new origin")
    inds = map(OffsetUnitRange, t, axes(a))
    unsafe_fast_subarray(view(a, inds...))
end

function offsetarray(::Type{T}, rs::AbstractUnitRange{<:Integer}...) where T
# returns array with undefined entries
    b = Array{T}(undef, map(length, rs))
    offsetarray(b, rs...)
end

# similar

function similar(a::AbstractArray, ::Type{T}, t::TupleVararg1{AbstractUnitRange{<:Integer}}) where T
    b = similar(a, T, map(length, t))
    offsetarray(b, t...)
end

function similar(::Type{A}, t::TupleVararg1{AbstractUnitRange{<:Integer}}) where A <: AbstractArray
# needed for broadcasting
    b = similar(A, map(length, t))
    offsetarray(b, t...)
end

# from1

from1(a::AbstractArray) = no_offset(a, axes(a)...)
from1(r::OffsetRange) = from1(values(r))

no_offset(a, ::OneTo...) = a
no_offset(a, rs...) =  view(a, map(no_range, rs)...)

no_range(r::OneTo) = r
no_range(r::AbstractUnitRange) = OffsetUnitRange(OneTo(length(r)), r)

# OffsetArrays

include("offsetarrays.jl")

end
