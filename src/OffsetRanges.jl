module OffsetRanges

export OffsetStepRange, OffsetUnitRange, offsetarray, from1

using Base: @propagate_inbounds, Fix1, OneTo, IdentityUnitRange, Slice
import Base: show, axes, step, length, step, first, last, getindex, isempty, values,
    similar, fill, reshape

const TupleVararg1{T} = Tuple{T, Vararg{T}}

argerror(s...) = throw(ArgumentError(s...))

# OffsetStepRange, OffsetUnitRange, OffsetRange

struct OffsetStepRange{T,S,P<:AbstractUnitRange{<:Integer},Q<:OrdinalRange{T,S}} <: OrdinalRange{T,S}
    inds::P
    vals::Q
end

_OffsetStepRange(inds::AbstractUnitRange, vals::OrdinalRange) = OffsetStepRange(values(inds), values(vals))

function OffsetStepRange(inds::AbstractUnitRange{<:Integer}, start, step)
    stop = start+step*(length(inds)-1)
    _OffsetStepRange(inds, start:step:stop)
end

struct OffsetUnitRange{T,P<:AbstractUnitRange{<:Integer},Q<:AbstractUnitRange{T}} <: AbstractUnitRange{T}
    inds::P
    vals::Q
end

_OffsetUnitRange(inds::AbstractUnitRange, vals::AbstractUnitRange) = OffsetUnitRange(values(inds), values(vals))

function OffsetUnitRange(inds::AbstractUnitRange{<:Integer}, start::Integer)
    stop = start+(length(inds)-1)
    _OffsetUnitRange(inds, start:stop)
end

OffsetUnitRange(inds::AbstractUnitRange{<:Integer}) = _OffsetUnitRange(inds, OneTo(length(inds)))

const OffsetRange{T} = Union{OffsetStepRange{T},OffsetUnitRange{T}}

(::Type{O})(start::Integer, r::OrdinalRange) where O <: OffsetRange = O(start:start+length(r)-1, values(r))

(::Type{O})(r::OffsetRange) where O <: OffsetRange = O(r.inds, r.vals)

show(io::IO, r::OffsetRange) = print(io, r.inds => values(r))

# axes(r::OffsetRange) = (first(r.inds):last(r.inds),)
axes(r::OffsetRange) = (IdentityUnitRange(r.inds),)

values(r::OffsetRange) = r.vals

step(r::OffsetStepRange) = step(values(r))

first(r::OffsetRange) = first(values(r))

last(r::OffsetRange) = last(values(r))

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

# support for IdentityUnitRange and Slice

values(r::AbstractRange) = r
values(r::IdentityUnitRange) = values(r.indices)
values(r::Slice) = values(r.indices)

@inline function getindex(r::OffsetUnitRange, s::IdentityUnitRange)
    @boundscheck checkbounds(r, s)
    @inbounds OffsetUnitRange(s, r[first(s)])
end

@inline function getindex(r::OffsetStepRange, s::IdentityUnitRange)
    @boundscheck checkbounds(r, s)
    @inbounds OffsetUnitRange(s, r[first(s)], step(r))
end

@propagate_inbounds getindex(r::OffsetRange, s::Slice) = r[axes(s, 1)]

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
    _OffsetUnitRange(s, r)
end

oa_range(r, n::Integer) = OffsetUnitRange(n, r)
oa_range(r, ::Colon) = Colon()
oa_range(r, ::T) where T = argerror("$T not supported to specify an axis")

decart(t) = t
decart(t, x, xs...) = decart((t..., x), xs...)
decart(t, x::CartesianIndex, xs...) = decart((t..., Tuple(x)...), xs...)
decart(t, x::CartesianIndices, xs...) = decart((t..., x.indices...), xs...)  # TODO: without "indices"?

function offsetarray(a::AbstractArray{T,N}, rs...) where {T,N}
    rsd = decart((), rs...)
    length(rsd) == N || argerror("array has dimension $N, but received $rs as new axes")
    unsafe_fast_subarray(view(a, map(oa_range, axes(a), rsd)...))
end

function offsetarray(::Type{T}, rs::AbstractUnitRange{<:Integer}...) where T
# returns array with undefined entries
    b = Array{T}(undef, map(length, rs))
    offsetarray(b, rs...)
end

# zeros, ones, trues, falses, similar, fill, reshape

for f in [:zeros, :ones]
    @eval function Base.$f(::Type{T}, t::TupleVararg1{AbstractUnitRange{<:Integer}}) where T
        b = $f(T, map(length, t))
        offsetarray(b, t...)
    end
end

for f in [:falses, :trues]
    @eval function Base.$f(t::TupleVararg1{AbstractUnitRange{<:Integer}})
        b = $f(map(length, t))
        offsetarray(b, t...)
    end
end

function similar(a::AbstractArray, ::Type{T}, t::TupleVararg1{AbstractUnitRange{<:Integer}}) where T
    b = similar(a, T, map(length, t))
    offsetarray(b, t...)
end

function similar(::Type{A}, t::TupleVararg1{AbstractUnitRange{<:Integer}}) where A <: AbstractArray
# needed for broadcasting
    b = similar(A, map(length, t))
    offsetarray(b, t...)
end

function fill(x, t::TupleVararg1{AbstractUnitRange{<:Integer}})
    b = fill(x, map(length, t))
    offsetarray(b, t...)
end

function reshape(x::AbstractArray, t::Union{Integer,AbstractUnitRange{<:Integer},Colon}...)
    b = reshape(x, map(x -> x isa AbstractUnitRange ? length(x) : x, t))
    offsetarray(b, map(x -> x isa Integer ? Colon() : x, t)...)
end

# to avoid ambiguities
reshape(x::AbstractArray, t::Colon...) = reshape(x, t)
reshape(x::AbstractArray) = reshape(x, ())

# from1

from1(a::AbstractArray) = _from1(a, axes(a)...)
from1(r::OffsetRange) = values(r)

_from1(a, ::OneTo...) = a
_from1(a, rs...) =  offsetarray(a, map(range1, rs)...)

range1(r::OneTo) = Colon()
range1(r::AbstractUnitRange) = OneTo(length(r))

# OffsetArrays

include("offsetarrays.jl")

end
