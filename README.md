# OffsetRanges.jl

> [!NOTE]
> This package is under construction. Since it is not registered, it must be installed with
> `add https://github.com/matthias314/OffsetRanges.jl` from the Julia package manager, or
> `add https://github.com/matthias314/OffsetRanges.jl#branch` for a specific branch.

This package provides the ranges `OffsetUnitRange` and `OffsetStepRange`
that are not 1-based, unlike their counterparts `UnitRange` and `StepRange`.
Via `view`, this may give a lightweight alternative to
[OffsetArrays.jl](https://github.com/JuliaArrays/OffsetArrays.jl),
see `offsetarray` below.
(As of this writing, OffsetArrays.jl has 1395 lines including docstrings,
while OffsetRanges.jl has 159 lines for offset ranges and `offsetarray`
plus 97 lines for OffsetArray.jl emulation. Docstrings are missing so far.)

See `Base.IdentityUnitRange` and
[IdentityRanges.jl](https://github.com/JuliaArrays/IdentityRanges.jl)
for offset ranges that map each index to itself.

## `OffsetUnitRange`

```
OffsetUnitRange(inds::AbstractUnitRange, vals::AbstractUnitRange)
OffsetUnitRange(inds::AbstractUnitRange, start::Integer)
```
This range maps the indices `inds` to the unit range `vals`. Both ranges must have the same length.
An integer as second argument means the unit range starting at that value.

```
julia> OffsetUnitRange(2:4, 5:7)
2:4 => 5:7

julia> r = OffsetUnitRange(2:4, 5)
2:4 => 5:7

julia> r[3]
6

julia> axes(r)
(2:4,)

julia> firstindex(r), lastindex(r)
(2, 4)

julia> values(r), first(r), last(r)
(5:7, 5, 7)
```

## `OffsetStepRange`

```
OffsetStepRange(inds::AbstractUnitRange, vals::OrdinalRange)
OffsetStepRange(inds::AbstractUnitRange, start::Integer, step::Integer)
```
This range maps the indices `inds` to the range `vals`. Both ranges must have the same length.
Integers as second and third argument mean the step range with the specified start and step value.

```
julia> OffsetStepRange(2:4, 5:2:9)
2:4 => 5:2:9

julia> r = OffsetStepRange(2:4, 5, 2)
2:4 => 5:2:9

julia> r[3]
7

julia> axes(r)
(2:4,)

julia> firstindex(r), lastindex(r)
(2, 4)

julia> values(r), first(r), step(r), last(r)
(5:2:9, 5, 2, 9)

julia> s = OffsetUnitRange(0:1, 3:4)
0:1 => 3:4

julia> r[s]
0:1 => 7:2:9
```

## `offsetarray`

```
offsetarray(a::AbstractArray, rs...)
offsetarray(::Type{T}, rs...) where T
```
This changes the axes of the array `a` to new unit ranges. An integer or `CartesianIndex` specifies
the start of the corresponding range. A `CartesianIndices` argument specifies a sequence of ranges.
A colon `:` represents an unchanged axis. These argument types can be mixed.
```
julia> a = [1 2 3; 4 5 6];

julia> offsetarray(a, 2:3, -1:1)
2×3 view(::Matrix{Int64}, 2:3 => Base.OneTo(2), -1:1 => Base.OneTo(3)) with eltype Int64 with indices 2:3×-1:1:
 1  2  3
 4  5  6

julia> offsetarray(a, 2, :)
2×3 view(::Matrix{Int64}, 2:3 => Base.OneTo(2), :) with eltype Int64 with indices 2:3×Base.OneTo(3):
 1  2  3
 4  5  6

julia> offsetarray(a, CartesianIndex(2), -1:1)
2×3 view(::Matrix{Int64}, 2:3 => Base.OneTo(2), -1:1 => Base.OneTo(3)) with eltype Int64 with indices 2:3×-1:1:
 1  2  3
 4  5  6

julia> offsetarray(a, CartesianIndex(2, -1):CartesianIndex(3, 1))
2×3 view(::Matrix{Int64}, 2:3 => Base.OneTo(2), -1:1 => Base.OneTo(3)) with eltype Int64 with indices 2:3×-1:1:
 1  2  3
 4  5  6
```

If the first argument is a type, then an array with this element type, the specified unit ranges
as axes and undefined values is returned.
```
julia> offsetarray(Int8, 2:3, -1:1)
2×3 view(::Matrix{Int8}, 2:3 => Base.OneTo(2), -1:1 => Base.OneTo(3)) with eltype Int8 with indices 2:3×-1:1:
 -96    7  -54
 -93  102  127
```

### `similar` and `fill`

The funtions `similar` and `fill` work with offset arrays and accept ranges as arguments:
```
julia> a = Int8[1 2 3; 4 5 6];

julia> b = offsetarray(a, 2, 3)
2×3 view(::Matrix{Int8}, 2:3 => Base.OneTo(2), 3:5 => Base.OneTo(3)) with eltype Int8 with indices 2:3×3:5:
 1  2  3
 4  5  6

julia> similar(b)
2×3 view(::Matrix{Int8}, 2:3 => Base.OneTo(2), 3:5 => Base.OneTo(3)) with eltype Int8 with indices 2:3×3:5:
 80   80  103
 47  107   68

julia> similar(b, 4:5, 6:7)
2×2 view(::Matrix{Int8}, 4:5 => Base.OneTo(2), 6:7 => Base.OneTo(2)) with eltype Int8 with indices 4:5×6:7:
 0    0
 8  -76

julia> fill(2, 8:9, -3:-1)
2×3 view(::Matrix{Int64}, 8:9 => Base.OneTo(2), -3:-1 => Base.OneTo(3)) with eltype Int64 with indices 8:9×-3:-1:
 2  2  2
 2  2  2
```

### `from1`

```
from1(a::AbstractArray)
```
This shifts the axes of the array `a` such that they start at `1`.
```
julia> b = offsetarray(a, 2:3, -1:1)
2×3 view(::Matrix{Int64}, 2:3 => Base.OneTo(2), -1:1 => Base.OneTo(3)) with eltype Int64 with indices 2:3×-1:1:
 1  2  3
 4  5  6

julia> from1(b)
2×3 view(::Matrix{Int64}, Base.OneTo(2) => 1:2, Base.OneTo(3) => 1:3) with eltype Int64:
 1  2  3
 4  5  6
```

## Emulating OffsetArrays.jl

The module `OffsetRanges.OffsetArrays` provides functions and types to emulate
[OffsetArrays.jl](https://github.com/JuliaArrays/OffsetArrays.jl).
It defines the types `OffsetVector`, `OffsetMatrix`, `OffsetArray`, `Origin` and `IdOffSetRange`
as well as the function `no_offset_view`. The value `undef` as first argument to `OffsetArray`
and friends is supported. Note that these types only act as constructors. The arrays created
by them are views.

For the examples from the `OffsetArray` docstring one gets:
```
julia> using OffsetRanges.OffsetArrays   # works without previous "using OffsetRanges"

julia> A = OffsetArray(reshape(1:6, 2, 3), -1, -2)
2×3 view(reshape(::UnitRange{Int64}, 2, 3), :, :) with eltype Int64 with indices 0:1×-1:1:
 1  3  5
 2  4  6

julia> OffsetArray(reshape(1:6, 2, 3), 0:1, -1:1)
2×3 view(reshape(::UnitRange{Int64}, 2, 3), :, :) with eltype Int64 with indices 0:1×-1:1:
 1  3  5
 2  4  6

julia> OffsetArray(reshape(1:6, 2, 3), :, -1:1)
2×3 view(reshape(::UnitRange{Int64}, 2, 3), :, :) with eltype Int64 with indices Base.OneTo(2)×-1:1:
 1  3  5
 2  4  6

julia> OffsetArray(reshape(1:6, 2, 3), CartesianIndex(0, -1):CartesianIndex(1, 1))
2×3 view(reshape(::UnitRange{Int64}, 2, 3), :, :) with eltype Int64 with indices 0:1×-1:1:
 1  3  5
 2  4  6

julia> OffsetArray(reshape(1:6, 2, 3), 0, -1:1)   # integers and ranges may be combined
2×3 view(reshape(::UnitRange{Int64}, 2, 3), :, :) with eltype Int64 with indices 1:2×-1:1:
 1  3  5
 2  4  6

julia> a = [1 2; 3 4];

julia> OffsetArray(a, OffsetArrays.Origin(0, 1))
2×2 view(::Matrix{Int64}, :, :) with eltype Int64 with indices 0:1×1:2:
 1  2
 3  4

julia> OffsetArray(a, OffsetArrays.Origin(0))
2×2 view(::Matrix{Int64}, :, :) with eltype Int64 with indices 0:1×0:1:
 1  2
 3  4
```

## Known issues

- Offset arrays made with this package are sometimes as fast as `OffsetArray`
  and sometimes slower by a factor of 1.7 (for example for adding two arrays). This seems to be
  somehow due to how broadcasting is implemented. Adding two offset arrays via a `for` loop is as
  fast as for `OffsetArray`.

- Arithmetic operations on ranges currently drop the offset.
  (This also affects `OffsetArrays.IdOffsetRange`.)

- When comparing ranges, the offset is currently not taken into account.
  (This also affects `OffsetArrays.IdOffsetRange`.) This should probably be fixed within Julia itself,
  see [JuliaLang/julia#54825](https://github.com/JuliaLang/julia/pull/54825).

- 1-element offset arrays behave strangely during broadcasting.
  See [JuliaLang/julia#30950](https://github.com/JuliaLang/julia/pull/30950).

- The (undocumented) methods `OffsetArray(missing, axes...)` and `OffsetArray(nothing, axes...)`
  are not supported. See `fill` above for an alternative.
