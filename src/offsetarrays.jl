module OffsetArrays

export OffsetVector, OffsetMatrix, OffsetArray, no_offset_view, IdOffsetRange, Origin

using Base: OneTo

using ..OffsetRanges
using OffsetRanges: argerror, decart

# IdOffsetRange

IdOffsetRange(r::AbstractUnitRange, offset = 0) =
    OffsetUnitRange(firstindex(r)+offset:lastindex(r)+offset, first(r)+offset:last(r)+offset)

# Origin

struct Origin{N}
    t::NTuple{N,Int}
end

Origin(ii::Integer...) = Origin(ii)
Origin(ci::CartesianIndex) = Origin(Tuple(ci))
Origin(a::AbstractArray) = Origin(map(first, axes(a)))

(o::Origin)(a::AbstractArray) = OffsetArray(a, o)

# OffsetArray

struct OffsetArray{T,N} <: AbstractArray{T,N}

function OffsetArray{T,N}(::UndefInitializer, t::Tuple) where {T,N}
    t2 = decart((), t...)
    length(t2) == N || argerror("wrong dimension: $N $t $t2")
    rs = map(t2) do x
        if !(x isa Integer)
            x
        elseif x >= 0
            OneTo(x)
        else
            argerror("negative array size")
        end
    end
    offsetarray(T, rs...)
end

function OffsetArray{T}(::UndefInitializer, t::Tuple) where T
    t2 = decart((), t...)
    # length(t2) == N || argerror("wrong dimension: $N $t $t2")
    rs = map(t2) do x
        if !(x isa Integer)
            x
        elseif x >= 0
            OneTo(x)
        else
            argerror("negative array size")
        end
    end
    offsetarray(T, rs...)
end

function OffsetArray{T,N}(x::T, rs::Tuple) where {T <: Union{Nothing,Missing}, N}
    @show rs
    error("stop")
end

OA_range(r, n::Integer) = r .+ n   #  first(r)+n:last(r)+n
OA_range(r, x) = x

function OffsetArray{T,N}(a::AbstractArray, rs::Tuple) where {T,N}
    rsd = decart((), rs...)
    length(rsd) == N || argerror("array has dimension $N, but received $rs as new axes")
    offsetarray(a, map(OA_range, axes(a), rsd)...)
end

function OffsetArray{T,N}(a::AbstractArray, (o,)::Tuple{Origin}) where {T,N}
    t = o.t == (0,) ? ntuple(Returns(0), N) : o.t
    offsetarray(a, t...)
end

OffsetArray{T,N}(a, rs...) where {T,N} = OffsetArray{T,N}(a, rs)

OffsetArray{T}(a, rs::Vararg{Any,N}) where {T,N} = OffsetArray{T,N}(a, rs...)
OffsetArray(a::AbstractArray{T,N}, rs...) where {T,N} = OffsetArray{T,N}(a, rs...)

end # OffsetArray

const OffsetVector{T} = OffsetArray{T,1}
const OffsetMatrix{T} = OffsetArray{T,2}

OffsetVector(a::AbstractVector{T}, rs...) where T = OffsetVector{T}(a, rs...)
OffsetMatrix(a::AbstractMatrix{T}, rs...) where T = OffsetMatrix{T}(a, rs...)

# no_offset_view

no_offset_view(a) = from1(a)

end
