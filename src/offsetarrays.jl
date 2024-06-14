module OffsetArrays

export OffsetVector, OffsetMatrix, OffsetArray, no_offset_view, IdOffsetRange, Origin

using ..OffsetRanges

# IdOffsetRange

IdOffsetRange(r::AbstractUnitRange, offset = 0) = OffsetUnitRange(1+offset, first(r)+offset:last(r)+offset)

# Origin currently in OffsetRanges

# OffsetArray

struct OffsetArray{T,N} <: AbstractArray{T,N}

OffsetArray{T,N}(::UndefInitializer, rs::Tuple) where {T,N} = similar(Array{T}, rs...)

function OffsetArray{T,N}(x::T, rs::Tuple{Vararg{AbstractUnitRange}}) where {T <: Union{Nothing,Missing}, N}
    b = Array{T,N}(x, map(length, rs))
    offsetarray(b, rs...)
end

function OffsetArray{T,N}(x::T, rs::Tuple{Vararg{Integer}}) where {T <: Union{Nothing,Missing}, N}
    Array{T,N}(x, rs)
end

function OffsetArray{T,N}(x::T, cis::Tuple{CartesianIndices}) where {T <: Union{Nothing,Missing}, N}
    OffsetArray{T,N}(x, cis[1].indices)
end

OffsetArray{T,N}(a::AbstractArray, rs::Tuple) where {T,N} = offsetarray(a, rs...)
# OffsetArray{T,N}(a::AbstractArray, (o,)::Tuple{Origin}) where {T,N} = offsetarray(a, o.t...)

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
